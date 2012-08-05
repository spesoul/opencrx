/*
 * ====================================================================
 * Project:     openCRX/Core, http://www.opencrx.org/
 * Name:        $Id: SubscriptionHandlerServlet.java,v 1.44 2008/09/06 20:09:32 wfro Exp $
 * Description: SubscriptionHandlerServlet
 * Revision:    $Revision: 1.44 $
 * Owner:       CRIXP AG, Switzerland, http://www.crixp.com
 * Date:        $Date: 2008/09/06 20:09:32 $
 * ====================================================================
 *
 * This software is published under the BSD license
 * as listed below.
 * 
 * Copyright (c) 2004-2008, CRIXP Corp., Switzerland
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * 
 * * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 
 * * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in
 * the documentation and/or other materials provided with the
 * distribution.
 * 
 * * Neither the name of CRIXP Corp. nor the names of the contributors
 * to openCRX may be used to endorse or promote products derived
 * from this software without specific prior written permission
 * 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 * ------------------
 * 
 * This product includes software developed by the Apache Software
 * Foundation (http://www.apache.org/).
 * 
 * This product includes software developed by contributors to
 * openMDX (http://www.openmdx.org/)
 */
package org.opencrx.kernel.workflow.servlet;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import javax.jdo.PersistenceManager;
import javax.jdo.PersistenceManagerFactory;
import javax.jmi.reflect.RefObject;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.opencrx.kernel.backend.Workflows;
import org.opencrx.kernel.base.cci2.AuditEntryQuery;
import org.opencrx.kernel.base.jmi1.AuditEntry;
import org.opencrx.kernel.base.jmi1.Auditee;
import org.opencrx.kernel.base.jmi1.ExecuteWorkflowParams;
import org.opencrx.kernel.base.jmi1.ObjectCreationAuditEntry;
import org.opencrx.kernel.base.jmi1.ObjectModificationAuditEntry;
import org.opencrx.kernel.base.jmi1.ObjectRemovalAuditEntry;
import org.opencrx.kernel.base.jmi1.TestAndSetVisitedByParams;
import org.opencrx.kernel.base.jmi1.TestAndSetVisitedByResult;
import org.opencrx.kernel.home1.jmi1.Subscription;
import org.opencrx.kernel.home1.jmi1.UserHome;
import org.opencrx.kernel.utils.Utils;
import org.opencrx.kernel.workflow1.jmi1.Topic;
import org.opencrx.kernel.workflow1.jmi1.WfProcess;
import org.openmdx.application.log.AppLog;
import org.openmdx.base.exception.ServiceException;
import org.openmdx.base.text.conversion.Base64;
import org.openmdx.compatibility.base.dataprovider.cci.DataproviderOperations;
import org.openmdx.compatibility.base.naming.Path;
import org.openmdx.kernel.id.UUIDs;
import org.openmdx.model1.accessor.basic.cci.Model_1_3;

/**
 * The SubscriptionHandlerServlet 'listens' for object modifications on incoming
 * audit entries. For each active subscription (i.e. topic target
 * pattern) which's filter (object identity and attribute filters) matches 
 * the modified object, the corresponding workflows are executed.
 */  
public class SubscriptionHandlerServlet 
    extends HttpServlet {

    //-----------------------------------------------------------------------
    public void init(
        ServletConfig config
    ) throws ServletException {

        super.init(config);
        this.model = Utils.createModel();
        // data connection
        try {
            this.persistenceManagerFactory = Utils.getPersistenceManagerFactory();
        }
        catch(Exception e) {
            throw new ServletException("can not get connection to data provider", e);
        }
    }

    //-----------------------------------------------------------------------
    private Short getEventType(
        AuditEntry auditEntry
    ) {
        return new Short( 
            auditEntry instanceof ObjectRemovalAuditEntry
                ? DataproviderOperations.OBJECT_REMOVAL
                : auditEntry instanceof ObjectCreationAuditEntry
                    ? DataproviderOperations.OBJECT_CREATION
                    : auditEntry instanceof ObjectModificationAuditEntry
                        ? DataproviderOperations.OBJECT_REPLACEMENT
                        : 0
        );                    
    }

    //-----------------------------------------------------------------------
    private boolean subscriptionAcceptsEventType(
        Subscription subscription,
        Short eventType
    ) {
        if(
            (subscription.getEventType() == null) || 
            (subscription.getEventType().size() == 0)
        ) {
            return true;
        }
        for(
            Iterator i = subscription.getEventType().iterator();
            i.hasNext();
        ) {
            Short e = new Short(((Number)i.next()).shortValue());
            if((e != null) && (eventType.compareTo(e) == 0)) {
                return true;
            }
        }
        return false;
    }
    
    //-----------------------------------------------------------------------
    private boolean testFilterValue(
        String filterName,
        String filterValue,
        Object message
    ) {
        // Filter name and value must be defined
        if((filterName != null) && (filterName.length() > 0)) { 
            Object messageValue = null;
            if(message instanceof RefObject) {
                try {
                    messageValue = ((RefObject)message).refGetValue(filterName);
                    // Get the first value if multi-valued
                    if(messageValue instanceof Collection) {
                        Collection messageValues = (Collection)messageValue;
                        messageValue = messageValues.isEmpty()
                            ? null
                            : messageValues.iterator().next();
                    }
                }
                catch(Exception e) {
                    AppLog.warning("Can not get filter value", e.getMessage());
                }
            }
            else {
                String messageAsString = message.toString();
                String indexedFilterName = filterName + ":\n0: ";
                int pos = -1;
                if((pos = messageAsString.indexOf(indexedFilterName)) >= 0) {
                    int start = pos + indexedFilterName.length();
                    int end = messageAsString.indexOf(
                        "\n", 
                        start
                    );
                    if(end > start) {
                        messageValue = messageAsString.substring(start, end);
                    }
                }                
            }
            return (filterValue == null) || (messageValue == null)
                ? messageValue == filterValue
                : messageValue.toString().equals(filterValue);
        }
        return true;
    }
    
    //-----------------------------------------------------------------------
    public boolean subscriptionAcceptsMessage(
        Subscription subscription,
        AuditEntry auditEntry
    ) {
        // Verify active flag and event type
        Short eventType = this.getEventType(auditEntry); 
        if(!subscription.isActive() || !this.subscriptionAcceptsEventType(subscription, eventType)) {
            return false;
        }
        /**
         * Check security. 
         * <ul>
         *   <li>If auditee is composite to a user's home only accept if user homes of 
         *       the subscription and the auditee are identical.
         *   <li>If the owner of the subscription has read-permission for auditee.
         * </ul>
         */        
        Object auditee = null; 
        if(auditEntry.getAuditee() != null) {
            Path auditeeIdentity = new Path(auditEntry.getAuditee());        
            Path userHomeIdentity = new Path(subscription.refMofId()).getParent().getParent();
            // Check identity of user homes
            if(
                (auditeeIdentity.size() >= PATH_PATTERN_USER_HOME.size()) &&
                auditeeIdentity.getPrefix(PATH_PATTERN_USER_HOME.size()).isLike(PATH_PATTERN_USER_HOME)
            ) {
                if(!auditeeIdentity.startsWith(userHomeIdentity)) {
                    return false;
                }
            }
            // Retrieve auditee in the security context of the home's principal. 
            // This validates availability and read-permissions.
            String principalName = userHomeIdentity.getBase();
            PersistenceManager pm = this.persistenceManagerFactory.getPersistenceManager(
                principalName,
                UUIDs.getGenerator().next().toString()
            );
            if(auditEntry instanceof ObjectModificationAuditEntry) {
                try {
                    auditee = pm.getObjectById(
                        new Path(auditEntry.getAuditee())
                    );
                }
                catch(Exception e) {
                    AppLog.detail(e.getMessage(), e.getCause());
                }
            }
            else if(auditEntry instanceof ObjectRemovalAuditEntry) {
                auditee = ((ObjectRemovalAuditEntry)auditEntry).getBeforeImage();
            }
            else if(auditEntry instanceof ObjectCreationAuditEntry) {
                try {
                    auditee = pm.getObjectById(
                        new Path(auditEntry.getAuditee())
                    );
                }
                catch(Exception e) {
                    AppLog.detail(e.getMessage(), e.getCause());
                }
            }   
            pm.close();
        }
        if(auditee == null) return false;
        
        // Prepare filter names and filter values
        List<String> filterNames = new ArrayList<String>();
        List filterValues = new ArrayList();
        if((subscription.getFilterName0() != null) && (subscription.getFilterName0().length() > 0)) {
            filterNames.add(subscription.getFilterName0());
            filterValues.add(subscription.getFilterValue0());
        }
        if((subscription.getFilterName1() != null) && (subscription.getFilterName1().length() > 0)) {
            filterNames.add(subscription.getFilterName1());
            filterValues.add(subscription.getFilterValue1());
        }
        if((subscription.getFilterName2() != null) && (subscription.getFilterName2().length() > 0)) {
            filterNames.add(subscription.getFilterName2());
            filterValues.add(subscription.getFilterValue2());
        }
        if((subscription.getFilterName3() != null) && (subscription.getFilterName3().length() > 0)) {
            filterNames.add(subscription.getFilterName3());
            filterValues.add(subscription.getFilterValue3());
        }
        if((subscription.getFilterName4() != null) && (subscription.getFilterName4().length() > 0)) {
            filterNames.add(subscription.getFilterName4());
            filterValues.add(subscription.getFilterValue4());
        }
        // Test values
        boolean acceptsMessage = true;
        for(int i = 0; i < filterNames.size(); i++) {     
            boolean acceptsValues = false;
            for(Iterator j = ((Set)filterValues.get(i)).iterator(); j.hasNext(); ) {
                acceptsValues |= this.testFilterValue(
                    (String)filterNames.get(i),
                    (String)j.next(),
                    auditee
                );
            }
            acceptsMessage &= acceptsValues;
            if(!acceptsMessage) break;
        }
        return acceptsMessage;
    }
        
    //-----------------------------------------------------------------------
    public boolean topicAcceptsObject(
        String providerName,
        String segmentName,
        Topic topic,
        String objectXri
    ) {
        String topicPatternXri = topic.getTopicPathPattern();
        if(topicPatternXri != null) {
            Path topicPattern = new Path(topicPatternXri);
            Path objectPath = new Path(objectXri);
            if(topicPattern.size() < 7) {
                return false;
            }
            else {
                return 
                    objectPath.isLike(topicPattern) &&
                    objectPath.get(2).equals(providerName) &&
                    objectPath.get(4).equals(segmentName);
            }
        }
        else {
            return false;
        }
    }        
    
    //-----------------------------------------------------------------------
    private List<Subscription> findSubscriptions(
        String providerName,
        String segmentName,
        org.opencrx.kernel.home1.jmi1.Home1Package homePkg,
        org.opencrx.kernel.workflow1.jmi1.Segment workflowSegment,
        org.opencrx.kernel.home1.jmi1.Segment userHomeSegment,
        AuditEntry auditEntry
    ) throws ServiceException {
        // Find topics matching the auditee (modified, created or removed object)
        List<Topic> matchingTopics = new ArrayList<Topic>();
        Collection<Topic> topics = workflowSegment.getTopic();
        for(Topic topic: topics) {
            if(this.topicAcceptsObject(providerName, segmentName, topic, auditEntry.getAuditee())) {
                matchingTopics.add(topic);
            }            
        }
        // Find subscriptions for this topic
        List<Subscription> matchingSubscriptions = null;
        if(!matchingTopics.isEmpty()) {
            matchingSubscriptions = new ArrayList<Subscription>();
            for(Topic topic: matchingTopics) {                
                org.opencrx.kernel.home1.cci2.SubscriptionQuery query = homePkg.createSubscriptionQuery();
                query.identity().like(
                    Utils.xriAsIdentityPattern("xri:@openmdx:org.opencrx.kernel.home1/provider/" + providerName + "/segment/" + segmentName + "/userHome/:*/subscription/:*")  
                );
                query.thereExistsTopic().equalTo(topic);                
                Collection<Subscription> subscriptions = userHomeSegment.getExtent(query);
                for(Subscription subscription: subscriptions) {
                    if(this.subscriptionAcceptsMessage(subscription, auditEntry)) {
                        matchingSubscriptions.add(subscription);
                    }
                }
            }
        }
        return matchingSubscriptions;
    }

    //-----------------------------------------------------------------------
    private void handleSubscriptions(
        String providerName,
        String segmentName,
        PersistenceManager pm,
        org.opencrx.kernel.base.jmi1.BasePackage basePkg,
        org.opencrx.kernel.home1.jmi1.Home1Package homePkg,
        org.opencrx.kernel.workflow1.jmi1.Segment workflowSegment,
        org.opencrx.kernel.home1.jmi1.Segment userHomeSegment,
        List<AuditEntry> auditEntries
    ) throws ServiceException {
        
        List<String> auditEntryXris = new ArrayList<String>();
        for(AuditEntry auditEntry: auditEntries) {
            auditEntryXris.add(auditEntry.refMofId());
            if(auditEntryXris.size() > BATCH_SIZE) break;
        }
        for(String auditEntryXri: auditEntryXris) {
            AuditEntry auditEntry = null;
            try {
                auditEntry = (AuditEntry)pm.getObjectById(new Path(auditEntryXri));
            } 
            catch(Exception e) {
                AppLog.warning("Can not access audit entry", Arrays.asList(new String[]{auditEntryXri, e.getMessage()}));
                AppLog.detail(e.getMessage(), e.getCause());
            }
            if(auditEntry != null) {
                TestAndSetVisitedByResult markAsVisistedReply = null;
                try {
                    TestAndSetVisitedByParams params = basePkg.createTestAndSetVisitedByParams(
                        VISITOR_ID
                    );
                    markAsVisistedReply = auditEntry.testAndSetVisitedBy(params);
                }
                catch(Exception e) {
                    AppLog.error("Can not invoke markAsVisited", e.getMessage());
                    ServiceException e0 = new ServiceException(e);
                    AppLog.error(e0.getMessage(), e0.getCause());
                }
                if(
                    (markAsVisistedReply != null) ||
                    (markAsVisistedReply.getVisitStatus() == 0)
                ) {
                    List<Subscription> subscriptions = this.findSubscriptions(
                        providerName,
                        segmentName,
                        homePkg,
                        workflowSegment,
                        userHomeSegment,
                        auditEntry
                    );
                    if(subscriptions != null) {
                        for(Subscription subscription: subscriptions) {
                            UserHome userHome = (UserHome)pm.getObjectById(
                                new Path(subscription.refMofId()).getParent().getParent()
                            );
                            org.opencrx.security.realm1.jmi1.User user = userHome.getOwningUser();
                            boolean userIsDisabled = false;
                            // Invalid NULLs on the DB may throw a NullPointer. Ignore.
                            try {
                                userIsDisabled = user.isDisabled();
                            } catch(Exception e) {}
                            // Execute all actions attached to the topic if owning user of user home is not disabled
                            if(!userIsDisabled) {
                                Collection<WfProcess> actions = subscription.getTopic().getPerformAction();
                                for(WfProcess performAction: actions) {
                                    // Execute workflow. A workflow instance is created for each
                                    // executed workflow. Synchronous workflows are executed immediately 
                                    // if startedOn and lastActivityOn are set. Pending workflow instances,
                                    // i.e. asynchronous and non-successful synchronous workflows are handled 
                                    // by the WorkflowControllerServlet.
                                    try {
                                        MessageDigest md = MessageDigest.getInstance("MD5");
                                        md.update(auditEntry.refMofId().getBytes("UTF-8"));
                                        md.update(performAction.refMofId().getBytes("UTF-8"));
                                        ExecuteWorkflowParams params = basePkg.createExecuteWorkflowParams(
                                            null,
                                            null,
                                            auditEntry.getAuditee(),
                                            Base64.encode(md.digest()).replace('/', '-'),
                                            new Integer(this.getEventType(auditEntry).intValue()),
                                            subscription,
                                            performAction
                                        );
                                        try {
                                            pm.currentTransaction().begin();
                                            userHome.executeWorkflow(params);
                                            pm.currentTransaction().commit();
                                        }
                                        catch(Exception e) {
                                            AppLog.warning("Can not execute workflow", performAction.getName() + "; home=" + userHome.refMofId());
                                            AppLog.warning(e.getMessage(), e.getCause());
                                            try {
                                                pm.currentTransaction().rollback();
                                            } catch(Exception e0) {}
                                        }
                                    }
                                    catch(NoSuchAlgorithmException e) {
                                        new ServiceException(e).log();
                                    }
                                    catch (UnsupportedEncodingException e) {
                                        new ServiceException(e).log();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }        
    }
    
    //-----------------------------------------------------------------------    
    public void handleSubscriptions(
        String id,
        String providerName,
        String segmentName,
        HttpServletRequest req, 
        HttpServletResponse res        
    ) throws IOException {
        
        System.out.println(new Date().toString() + ": " + WORKFLOW_NAME + " " + providerName + "/" + segmentName);

        try {
            PersistenceManager pm = this.persistenceManagerFactory.getPersistenceManager(
                "admin-" + segmentName,
                UUIDs.getGenerator().next().toString()
            );
            Workflows.initWorkflows(
                pm,
                providerName,
                segmentName                
            );
            
            // Get auditees
            List<Auditee> auditSegments = new ArrayList<Auditee>();
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.account1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.activity1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.building1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.contract1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.depot1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.document1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.forecast1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.model1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.product1/provider/" + providerName + "/segment/" + segmentName))
            );
            auditSegments.add(
                (Auditee)pm.getObjectById(new Path("xri:@openmdx:org.opencrx.kernel.home1/provider/" + providerName + "/segment/" + segmentName))
            );
                                
            // Workflow segment
            org.opencrx.kernel.workflow1.jmi1.Segment workflowSegment = (org.opencrx.kernel.workflow1.jmi1.Segment)pm.getObjectById(
                new Path("xri:@openmdx:org.opencrx.kernel.workflow1/provider/" + providerName + "/segment/" + segmentName)
            );
            // User home segment
            org.opencrx.kernel.home1.jmi1.Segment userHomeSegment = (org.opencrx.kernel.home1.jmi1.Segment)pm.getObjectById(
                new Path("xri:@openmdx:org.opencrx.kernel.home1/provider/" + providerName + "/segment/" + segmentName)
            );                    
            // base package
            org.opencrx.kernel.base.jmi1.BasePackage basePkg = Utils.getBasePackage(pm);
            org.opencrx.kernel.home1.jmi1.Home1Package homePkg = Utils.getHomePackage(pm);
            
            // Iterate all auditees and check for new audit entries
            for(Auditee auditee: auditSegments) {
                AuditEntryQuery query = basePkg.createAuditEntryQuery();
                // Not visited elements are marked with VISITOR_ID:-
                // Visited elements are marked with VISITOR_ID:<time stamp of visit>
                query.thereExistsVisitedBy().equalTo(
                    VISITOR_ID + ":-"
                );
                try {
                    List<AuditEntry> auditEntries = auditee.getAudit(query);
                    this.handleSubscriptions(   
                        providerName,
                        segmentName,
                        pm,
                        basePkg,
                        homePkg,
                        workflowSegment,
                        userHomeSegment,
                        auditEntries
                    );
                }
                catch(Exception e) {
                    new ServiceException(e).log();                    
                    System.out.println(new Date() + ": " + WORKFLOW_NAME + " " + providerName + "/" + segmentName + ": exception occured " + e.getMessage() + ". Continuing");                    
                }
            }
            try {
                pm.close();
            } catch(Exception e) {}
        }
        catch(Exception e) {
            new ServiceException(e).log();
            System.out.println(new Date() + ": " + WORKFLOW_NAME + " " + providerName + "/" + segmentName + ": exception occured " + e.getMessage() + ". Continuing");
        }        
    }
    
    //-----------------------------------------------------------------------
    protected void handleRequest(
        HttpServletRequest req, 
        HttpServletResponse res
    ) throws ServletException, IOException {
        if(System.currentTimeMillis() > this.startedAt + 180000L) {
            String segmentName = req.getParameter("segment");
            String providerName = req.getParameter("provider");
            String id = providerName + "/" + segmentName;
            // run
            if(
                COMMAND_EXECUTE.equals(req.getPathInfo()) &&
                !this.runningSegments.contains(id)
            ) {
                try {
                    this.runningSegments.add(id);
                    this.handleSubscriptions(
                        id,
                        providerName,
                        segmentName,
                        req,
                        res
                    );
                } catch(Exception e) {
                    new ServiceException(e).log();
                }
                finally {
                    this.runningSegments.remove(id);
                }
            }
        }
    }

    //-----------------------------------------------------------------------
    protected void doGet(
        HttpServletRequest req, 
        HttpServletResponse res
    ) throws ServletException, IOException {
        res.setStatus(HttpServletResponse.SC_OK);
        res.flushBuffer();
        this.handleRequest(
            req,
            res
        );
    }
        
    //-----------------------------------------------------------------------
    protected void doPost(
        HttpServletRequest req, 
        HttpServletResponse res
    ) throws ServletException, IOException {
        res.setStatus(HttpServletResponse.SC_OK);
        res.flushBuffer();
        this.handleRequest(
            req,
            res
        );
    }
        
    //-----------------------------------------------------------------------
    // Members
    //-----------------------------------------------------------------------
    private static final long serialVersionUID = 7074135054692868453L;
    private static final int BATCH_SIZE = 50;
    
    private static final String WORKFLOW_NAME = "SubscriptionHandler";    
    private static final Path PATH_PATTERN_USER_HOME = new Path("xri:@openmdx:org.opencrx.kernel.home1/provider/:*/segment/:*/userHome/:*");
    private static final String COMMAND_EXECUTE = "/execute";
    private static final String VISITOR_ID = "SubscriptionHandler";

    private PersistenceManagerFactory persistenceManagerFactory = null;
    private final List<String> runningSegments = new ArrayList<String>();
    private long startedAt = System.currentTimeMillis();
    private Model_1_3 model = null;
}

//--- End of File -----------------------------------------------------------