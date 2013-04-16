/*
 * ====================================================================
 * Project:     openCRX/Core, http://www.opencrx.org/
 * Description: CreateActivityAction
 * Owner:       CRIXP AG, Switzerland, http://www.crixp.com
 * ====================================================================
 *
 * This software is published under the BSD license
 * as listed below.
 * 
 * Copyright (c) 2004-2012, CRIXP Corp., Switzerland
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
package org.opencrx.application.bpi.adapter;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import javax.jdo.PersistenceManager;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.opencrx.application.bpi.datatype.BpiCreateActivityParams;
import org.opencrx.kernel.account1.jmi1.Contact;
import org.opencrx.kernel.activity1.jmi1.ActivityCreator;
import org.opencrx.kernel.activity1.jmi1.NewActivityParams;
import org.opencrx.kernel.activity1.jmi1.NewActivityResult;
import org.opencrx.kernel.backend.ICalendar;
import org.openmdx.base.exception.ServiceException;
import org.openmdx.base.naming.Path;
import org.w3c.spi2.Datatypes;
import org.w3c.spi2.Structures;

/**
 * CreateActivityAction
 *
 */
public class CreateActivityAction extends BpiAction {

	/* (non-Javadoc)
	 * @see org.opencrx.application.bpi.adapter.BpiAdapterServlet.Action#handle(org.openmdx.base.naming.Path, javax.jdo.PersistenceManager, javax.servlet.http.HttpServletRequest, javax.servlet.http.HttpServletResponse)
	 */
	@Override
    public void perform(
    	Path path, PersistenceManager pm,
    	BpiPlugIn plugIn,
    	HttpServletRequest req, 
    	HttpServletResponse resp
    ) throws IOException, ServiceException {
    	List<ActivityCreator> activityCreators = plugIn.findActivityCreators(path.getPrefix(7), pm);
    	if(activityCreators == null || activityCreators.isEmpty()) {
    		resp.setStatus(HttpServletResponse.SC_NOT_FOUND);    		
    	} else {
    		ActivityCreator activityCreator = activityCreators.iterator().next();
    		BpiCreateActivityParams bpiCreateActivityParams = plugIn.parseObject(
    			req.getReader(),
    			BpiCreateActivityParams.class
    		);
    		Contact reportingContact = null;
    		try {
    			String contactId = bpiCreateActivityParams.getReportingContact();
    			if(contactId != null) {
    				List<Contact> contacts = plugIn.findContacts(path.getPrefix(5).getDescendant("contact", contactId), pm);
    				reportingContact = contacts.isEmpty() ? null : contacts.iterator().next();
    			}
    		} catch(Exception ignore) {}
    		try {
	    		pm.currentTransaction().begin();
	    		NewActivityParams params = Structures.create(
	    			NewActivityParams.class,
	    			Datatypes.member(NewActivityParams.Member.name, bpiCreateActivityParams.getName()),
	    			Datatypes.member(NewActivityParams.Member.description, bpiCreateActivityParams.getDescription()),
	    			Datatypes.member(NewActivityParams.Member.detailedDescription, bpiCreateActivityParams.getDetailedDescription()),
	    			Datatypes.member(NewActivityParams.Member.scheduledStart, bpiCreateActivityParams.getScheduledStart()),
	    			Datatypes.member(NewActivityParams.Member.scheduledEnd, bpiCreateActivityParams.getScheduledEnd()),
	    			Datatypes.member(NewActivityParams.Member.priority, bpiCreateActivityParams.getPriority()),
	    			Datatypes.member(NewActivityParams.Member.icalType, ICalendar.ICAL_TYPE_NA),
	    			Datatypes.member(NewActivityParams.Member.reportingContact, reportingContact)
	    		);
	    		NewActivityResult result = activityCreator.newActivity(params);
	    		pm.currentTransaction().commit();
	    		if(result.getActivity() != null) {
	        		resp.setCharacterEncoding("UTF-8");
	        		resp.setContentType("application/json");
	        		PrintWriter pw = resp.getWriter();
	        		plugIn.printObject(pw, plugIn.toBpiActivity(result.getActivity(), plugIn.newBpiActivity()));
	        		resp.setStatus(HttpServletResponse.SC_OK);
	    		}
    		} catch(Exception e) {
    			new ServiceException(e).log();
    			try {
    				pm.currentTransaction().rollback();
    			} catch(Exception ignore) {}
    		}
    	}
    }

}