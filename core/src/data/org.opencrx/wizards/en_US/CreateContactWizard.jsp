<%@  page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %><%
/*
 * ====================================================================
 * Project:     openCRX/Core, http://www.openmdx.org/
 * Name:        $Id: CreateContactWizard.jsp,v 1.21 2009/05/11 12:12:32 cmu Exp $
 * Description: CreateContact wizard
 * Revision:    $Revision: 1.21 $
 * Owner:       CRIXP AG, Switzerland, http://www.crixp.com
 * Date:        $Date: 2009/05/11 12:12:32 $
 * ====================================================================
 *
 * This software is published under the BSD license
 * as listed below.
 *
 * Copyright (c) 2005-2009, CRIXP Corp., Switzerland
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
%><%@ page session="true" import="
java.util.*,
java.io.*,
java.text.*,
org.opencrx.kernel.backend.Accounts,
org.opencrx.kernel.portal.*,
org.openmdx.kernel.id.cci.*,
org.openmdx.kernel.id.*,
org.openmdx.base.text.conversion.*,
org.openmdx.base.accessor.jmi.cci.*,
org.openmdx.portal.servlet.*,
org.openmdx.portal.servlet.attribute.*,
org.openmdx.portal.servlet.view.*,
org.openmdx.portal.servlet.databinding.*,
org.openmdx.portal.servlet.texts.*,
org.openmdx.portal.servlet.control.*,
org.openmdx.portal.servlet.reports.*,
org.openmdx.portal.servlet.wizards.*,
org.openmdx.base.naming.*,
org.openmdx.application.log.*
" %><%
	request.setCharacterEncoding("UTF-8");
	String servletPath = "." + request.getServletPath();
	String servletPathPrefix = servletPath.substring(0, servletPath.lastIndexOf("/") + 1);
	ApplicationContext app = (ApplicationContext)session.getValue(WebKeys.APPLICATION_KEY);
	ViewsCache viewsCache = (ViewsCache)session.getValue(WebKeys.VIEW_CACHE_KEY_SHOW);
	String requestId =  request.getParameter(Action.PARAMETER_REQUEST_ID);
	String objectXri = request.getParameter(Action.PARAMETER_OBJECTXRI);
	if(objectXri == null || app == null || viewsCache.getViews().isEmpty()) {
		response.sendRedirect(
			request.getContextPath() + "/" + WebKeys.SERVLET_NAME
		);
		return;
	}
	javax.jdo.PersistenceManager pm = app.getPmData();
	RefObject_1_0 obj = (RefObject_1_0)pm.getObjectById(new Path(objectXri));
	Texts_1_0 texts = app.getTexts();
	Codes codes = app.getCodes();
	String formName = "CreateContactForm";
	String wizardName = "CreateContactWizard";
	
	// Get Parameters
	String command = request.getParameter("Command");
	if(command == null) command = "";	
	boolean actionSave = "OK".equals(command);
	boolean actionCancel = "Cancel".equals(command);
	boolean actionSearch = "Search".equals(command);
	boolean actionCreate = "Create".equals(command);

	List matchingAccounts = null;
	if(actionCancel) {
	  session.setAttribute(wizardName, null);
		Action nextAction = new ObjectReference(obj, app).getSelectObjectAction();
		response.sendRedirect(
			request.getContextPath() + "/" + nextAction.getEncodedHRef()
		);
		return;
	}
%>
<!--
	<meta name="UNUSEDlabel" content="Create Contact">
	<meta name="UNUSEDtoolTip" content="Create Contact">
	<meta name="targetType" content="_inplace">
	<meta name="forClass" content="org:opencrx:kernel:account1:Segment">
	<meta name="forClass" content="org:opencrx:kernel:account1:Contact">
	<meta name="order" content="org:opencrx:kernel:account1:Segment:createContact">
	<meta name="order" content="org:opencrx:kernel:account1:Contact:createContact">
-->
<%
	org.opencrx.kernel.account1.jmi1.Account account = null;
	org.opencrx.kernel.account1.jmi1.Segment accountSegment = null;
	if(obj instanceof org.opencrx.kernel.account1.jmi1.Account) {
	    account = (org.opencrx.kernel.account1.jmi1.Account)obj;
	    accountSegment = (org.opencrx.kernel.account1.jmi1.Segment)pm.getObjectById(account.refGetPath().getParent().getParent());
	}
	else if(obj instanceof org.opencrx.kernel.account1.jmi1.Segment) {
	    accountSegment = (org.opencrx.kernel.account1.jmi1.Segment)obj;
	}
	org.openmdx.ui1.jmi1.FormDefinition formDefinition = app.getUiFormDefinition(formName);
	org.openmdx.portal.servlet.control.FormControl form = new org.openmdx.portal.servlet.control.FormControl(
		formDefinition.refGetPath().getBase(),
		app.getCurrentLocaleAsString(),
		app.getCurrentLocaleAsIndex(),
		app.getUiContext(),
		formDefinition
	);
	Map formValues = new HashMap();
	// Initialize formValues with account values
	if(account != null && account instanceof org.opencrx.kernel.account1.jmi1.Contact) {
	    org.opencrx.kernel.account1.jmi1.Contact contact = (org.opencrx.kernel.account1.jmi1.Contact)account;
	    formValues.put("org:opencrx:kernel:account1:Contact:salutationCode", contact.getSalutationCode());
	    formValues.put("org:opencrx:kernel:account1:Contact:salutation", contact.getSalutation());
	    formValues.put("org:opencrx:kernel:account1:Contact:firstName", contact.getFirstName());
	    formValues.put("org:opencrx:kernel:account1:Contact:middleName", contact.getMiddleName());
	    formValues.put("org:opencrx:kernel:account1:Contact:lastName", contact.getLastName());
	    formValues.put("org:opencrx:kernel:account1:Account:aliasName", contact.getAliasName());
	    formValues.put("org:opencrx:kernel:account1:Contact:jobTitle", contact.getJobTitle());
	    formValues.put("org:opencrx:kernel:account1:Contact:jobRole", contact.getJobRole());
	    formValues.put("org:opencrx:kernel:account1:Contact:organization", contact.getOrganization());
	    formValues.put("org:opencrx:kernel:account1:Contact:department", contact.getDepartment());
	    formValues.put("org:opencrx:kernel:account1:Contact:doNotPhone", contact.isDoNotPhone());
	    formValues.put("org:opencrx:kernel:account1:Contact:birthdate", contact.getBirthdate());
	    formValues.put("org:opencrx:kernel:account1:Account:description", contact.getDescription());
	    org.opencrx.kernel.account1.jmi1.AccountAddress[] addresses = Accounts.getInstance().getMainAddresses(account);
	    if(addresses[Accounts.PHONE_BUSINESS] != null) {
	    	formValues.put("org:opencrx:kernel:account1:Account:address*Business!phoneNumberFull", ((org.opencrx.kernel.account1.jmi1.PhoneNumber)addresses[Accounts.PHONE_BUSINESS]).getPhoneNumberFull());
	    }
	    if(addresses[Accounts.MOBILE] != null) {
	    	formValues.put("org:opencrx:kernel:account1:Account:address*Mobile!phoneNumberFull", ((org.opencrx.kernel.account1.jmi1.PhoneNumber)addresses[Accounts.MOBILE]).getPhoneNumberFull());
	    }
	    if(addresses[Accounts.PHONE_HOME] != null) {
	    	formValues.put("org:opencrx:kernel:account1:Contact:address!phoneNumberFull", ((org.opencrx.kernel.account1.jmi1.PhoneNumber)addresses[Accounts.PHONE_HOME]).getPhoneNumberFull());
	    }
	    if(addresses[Accounts.MAIL_BUSINESS] != null) {
	    	formValues.put("org:opencrx:kernel:account1:Account:address*Business!emailAddress", ((org.opencrx.kernel.account1.jmi1.EMailAddress)addresses[Accounts.MAIL_BUSINESS]).getEmailAddress());
	    }
	    if(addresses[Accounts.MAIL_HOME] != null) {
	    	formValues.put("org:opencrx:kernel:account1:Contact:address!emailAddress", ((org.opencrx.kernel.account1.jmi1.EMailAddress)addresses[Accounts.MAIL_HOME]).getEmailAddress());
	    }
	    if(addresses[Accounts.POSTAL_HOME] != null) {
		    formValues.put("org:opencrx:kernel:account1:Contact:address!postalAddressLine", new ArrayList(((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_HOME]).getPostalAddressLine()));
		    formValues.put("org:opencrx:kernel:account1:Contact:address!postalStreet", new ArrayList(((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_HOME]).getPostalStreet()));
		    formValues.put("org:opencrx:kernel:account1:Contact:address!postalCity", ((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_HOME]).getPostalCity());
		    formValues.put("org:opencrx:kernel:account1:Contact:address!postalCode", ((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_HOME]).getPostalCode());
		    formValues.put("org:opencrx:kernel:account1:Contact:address!postalCountry", ((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_HOME]).getPostalCountry());
	    }
	    if(addresses[Accounts.POSTAL_BUSINESS] != null) {
		    formValues.put("org:opencrx:kernel:account1:Account:address*Business!postalAddressLine", new ArrayList(((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_BUSINESS]).getPostalAddressLine()));
		    formValues.put("org:opencrx:kernel:account1:Account:address*Business!postalStreet", new ArrayList(((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_BUSINESS]).getPostalStreet()));
		    formValues.put("org:opencrx:kernel:account1:Account:address*Business!postalCity", ((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_BUSINESS]).getPostalCity());
		    formValues.put("org:opencrx:kernel:account1:Account:address*Business!postalCode", ((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_BUSINESS]).getPostalCode());
		    formValues.put("org:opencrx:kernel:account1:Account:address*Business!postalCountry", ((org.opencrx.kernel.account1.jmi1.PostalAddress)addresses[Accounts.POSTAL_BUSINESS]).getPostalCountry());
	    }
	}
	form.updateObject(
		request.getParameterMap(),
		formValues,
		app,
		pm
	);
	// Search
    List matchingContacts = null;
	if(actionSearch) {
	    boolean hasQueryProperty = false;
	    org.opencrx.kernel.account1.cci2.ContactQuery contactQuery =
	        (org.opencrx.kernel.account1.cci2.ContactQuery)pm.newQuery(org.opencrx.kernel.account1.jmi1.Contact.class);
		contactQuery.orderByFullName().ascending();
	    String firstName = (String)formValues.get("org:opencrx:kernel:account1:Contact:firstName");
	    String lastName = (String)formValues.get("org:opencrx:kernel:account1:Contact:lastName");
	    String aliasName = (String)formValues.get("org:opencrx:kernel:account1:Account:aliasName");
	    String phoneNumberMobile = (String)formValues.get("org:opencrx:kernel:account1:Account:address*Mobile!phoneNumberFull");
	    String phoneNumberHome = (String)formValues.get("org:opencrx:kernel:account1:Contact:address!phoneNumberFull");
	    String phoneNumberBusiness = (String)formValues.get("org:opencrx:kernel:account1:Account:address*Business!phoneNumberFull");
	    String postalCityHome = (String)formValues.get("org:opencrx:kernel:account1:Contact:address!postalCity");
	    String postalCityBusiness = (String)formValues.get("org:opencrx:kernel:account1:Contact:address*Business!postalCity");
	    List postalStreetHome = (List)formValues.get("org:opencrx:kernel:account1:Contact:address!postalStreet");
	    List postalStreetBusiness = (List)formValues.get("org:opencrx:kernel:account1:Contact:address*Business!postalStreet");
	    String emailHome = (String)formValues.get("org:opencrx:kernel:account1:Contact:address!emailAddress");
	    String emailBusiness = (String)formValues.get("org:opencrx:kernel:account1:Account:address*Business!emailAddress");
	    if(firstName != null) {
	        hasQueryProperty = true;
	        contactQuery.thereExistsFirstName().like("(?i).*" + firstName + ".*");
	    }
	    if(lastName != null) {
	        hasQueryProperty = true;
	        contactQuery.thereExistsLastName().like("(?i).*" + lastName + ".*");
	    }
	    if(aliasName != null) {
	        hasQueryProperty = true;
	        contactQuery.thereExistsAliasName().like("(?i).*" + aliasName + ".*");
	    }
	    String queryFilterClause = null;
	    List stringParams = new ArrayList();
	    int stringParamIndex = 0;
	    if(phoneNumberMobile != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.phone_number_full = ?s" + stringParamIndex++ + ")";
	        stringParams.add(phoneNumberMobile);
	    }
	    if(phoneNumberHome != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.phone_number_full = ?s" + stringParamIndex++ + ")";
	        stringParams.add(phoneNumberHome);
	    }
	    if(phoneNumberBusiness != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.phone_number_full = ?s" + stringParamIndex++ + ")";
	        stringParams.add(phoneNumberBusiness);
	    }
	    if(postalCityHome != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.postal_city LIKE ?s" + stringParamIndex++ + ")";
	        stringParams.add("%" + postalCityHome + "%");
	    }
	    if(postalCityBusiness != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.postal_city LIKE ?s" + stringParamIndex++ + ")";
	        stringParams.add("%" + postalCityBusiness + "%");
	    }
	    if(postalStreetHome != null) {
	        for(int i = 0; i < postalStreetHome.size(); i++) {
		        hasQueryProperty = true;
		        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
		        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.postal_street_" + i + " LIKE ?s" + stringParamIndex++ + ")";
		        stringParams.add("%" + postalStreetHome.get(i) + "%");
	        }
	    }
	    if(postalStreetBusiness != null) {
	        for(int i = 0; i < postalStreetBusiness.size(); i++) {
		        hasQueryProperty = true;
		        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
		        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.postal_street_" + i + " LIKE ?s" + stringParamIndex++ + ")";
		        stringParams.add("%" + postalStreetBusiness.get(i) + "%");
	        }
	    }
	    if(emailHome != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.email_address = ?s" + stringParamIndex++ + ")";
	        stringParams.add(emailHome);
	    }
	    if(emailBusiness != null) {
	        hasQueryProperty = true;
	        if(stringParamIndex > 0) { queryFilterClause += " AND "; } else { queryFilterClause = ""; }
	        queryFilterClause += "v.object_id IN (SELECT act.object_id FROM OOCKE1_ACCOUNT act INNER JOIN OOCKE1_ADDRESS adr ON adr.p$$parent = act.object_id WHERE adr.email_address = ?s" + stringParamIndex++ + ")";
	        stringParams.add(emailBusiness);
	    }
	    if(queryFilterClause != null) {
		    org.openmdx.compatibility.datastore1.jmi1.QueryFilter queryFilter =
	        	pm.newInstance(org.openmdx.compatibility.datastore1.jmi1.QueryFilter.class);
		    queryFilter.setClause(queryFilterClause);
		    queryFilter.setStringParam(stringParams);
		    contactQuery.thereExistsContext().equalTo(queryFilter);
	    }
	    matchingContacts = hasQueryProperty ?
	        accountSegment.getAccount(contactQuery) :
	        null;
	}
	else if(actionCreate || actionSave) {
	    // Contact
	    org.opencrx.kernel.account1.jmi1.Contact contact = null;
	    if(actionCreate) {
		    contact = pm.newInstance(org.opencrx.kernel.account1.jmi1.Contact.class);
	    	contact.refInitialize(false, false);
	    }
	    else {
	        contact = (org.opencrx.kernel.account1.jmi1.Contact)account;
	    }
	    String aliasName = (String)formValues.get("org:opencrx:kernel:account1:Account:aliasName");
	    if(aliasName == null) {
	        org.opencrx.kernel.account1.cci2.AccountQuery accountQuery =
	            (org.opencrx.kernel.account1.cci2.AccountQuery)pm.newQuery(org.opencrx.kernel.account1.jmi1.Account.class);
	        accountQuery.thereExistsAliasName().greaterThanOrEqualTo("A00000000");
	        accountQuery.thereExistsAliasName().lessThanOrEqualTo("A99999999");
	        accountQuery.orderByAliasName().descending();
	        List accounts = accountSegment.getAccount(accountQuery);
	        if(accounts.isEmpty()) {
	            aliasName = "A00000000";
	        }
	        else {
	            String lastAliasName = ((org.opencrx.kernel.account1.jmi1.Account)accounts.iterator().next()).getAliasName();
	            String nextAccountNumber = "00000000" + (Integer.valueOf(lastAliasName.substring(1)).intValue() + 1);
	            aliasName = "A" + nextAccountNumber.substring(nextAccountNumber.length() - 8);
	        }
	        formValues.put(
                "org:opencrx:kernel:account1:Account:aliasName",
                aliasName
	        );
	    }
	    pm.currentTransaction().begin();
	    contact.setSalutationCode(((Number)formValues.get("org:opencrx:kernel:account1:Contact:salutationCode")).shortValue());
	    contact.setSalutation((String)formValues.get("org:opencrx:kernel:account1:Contact:salutation"));
	    contact.setFirstName((String)formValues.get("org:opencrx:kernel:account1:Contact:firstName"));
	    contact.setMiddleName((String)formValues.get("org:opencrx:kernel:account1:Contact:middleName"));
	    contact.setLastName((String)formValues.get("org:opencrx:kernel:account1:Contact:lastName"));
	    contact.setAliasName(aliasName);
	    contact.setJobTitle((String)formValues.get("org:opencrx:kernel:account1:Contact:jobTitle"));
	    contact.setJobRole((String)formValues.get("org:opencrx:kernel:account1:Contact:jobRole"));
	    contact.setOrganization((String)formValues.get("org:opencrx:kernel:account1:Contact:organization"));
	    contact.setDepartment((String)formValues.get("org:opencrx:kernel:account1:Contact:department"));
	    contact.setDoNotPhone((Boolean)formValues.get("org:opencrx:kernel:account1:Contact:doNotPhone"));
	    contact.setBirthdate((Date)formValues.get("org:opencrx:kernel:account1:Contact:birthdate"));
	    contact.setDescription((String)formValues.get("org:opencrx:kernel:account1:Account:description"));
	    if(actionCreate) {
		    accountSegment.addAccount(
		        false,
		        org.opencrx.kernel.backend.Accounts.getInstance().getUidAsString(),
		        contact
		    );
	    }
	    pm.currentTransaction().commit();
	    account = contact;
	    // Update Addresses
	    pm.currentTransaction().begin();
	    // Phone Business
	    DataBinding_1_0 phoneBusinessDataBinding = new PhoneNumberDataBinding("[isMain=(boolean)true];usage=(short)500;automaticParsing=(boolean)true");
	    phoneBusinessDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!phoneNumberFull",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!phoneNumberFull")
	    );
	    // Phone Mobile
	    DataBinding_1_0 phoneMobileDataBinding = new PhoneNumberDataBinding("[isMain=(boolean)true];usage=(short)200;automaticParsing=(boolean)true");
	    phoneMobileDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Mobile!phoneNumberFull",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Mobile!phoneNumberFull")
	    );
	    // Phone Home
	    DataBinding_1_0 phoneHomeDataBinding = new PhoneNumberDataBinding("[isMain=(boolean)true];usage=(short)400;automaticParsing=(boolean)true");
	    phoneHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!phoneNumberFull",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!phoneNumberFull")
	    );
	    // Mail Business
	    DataBinding_1_0 mailBusinessDataBinding = new EmailAddressDataBinding("[isMain=(boolean)true];usage=(short)500;[emailType=(short)1]");
	    mailBusinessDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!emailAddress",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!emailAddress")
	    );
	    // Mail Home
	    DataBinding_1_0 mailHomeDataBinding = new EmailAddressDataBinding("[isMain=(boolean)true];usage=(short)400;[emailType=(short)1]");
	    mailHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!emailAddress",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!emailAddress")
	    );
	    // Postal Home
	    DataBinding_1_0 postalHomeDataBinding = new PostalAddressDataBinding("[isMain=(boolean)true];usage=(short)400?zeroAsNull=true");
	    postalHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!postalAddressLine",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!postalAddressLine")
	    );
	    postalHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!postalStreet",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!postalStreet")
	    );
	    postalHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!postalCity",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!postalCity")
	    );
	    postalHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!postalCode",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!postalCode")
	    );
	    postalHomeDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Contact:address!postalCountry",
	        formValues.get("org:opencrx:kernel:account1:Contact:address!postalCountry")
	    );
	    // Postal Business
	    DataBinding_1_0 postalBusinesDataBinding = new PostalAddressDataBinding("[isMain=(boolean)true];usage=(short)500?zeroAsNull=true");
	    postalBusinesDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!postalAddressLine",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!postalAddressLine")
	    );
	    postalBusinesDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!postalStreet",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!postalStreet")
	    );
	    postalBusinesDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!postalCity",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!postalCity")
	    );
	    postalBusinesDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!postalCode",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!postalCode")
	    );
	    postalBusinesDataBinding.setValue(
	        contact,
	        "org:opencrx:kernel:account1:Account:address*Business!postalCountry",
	        formValues.get("org:opencrx:kernel:account1:Account:address*Business!postalCountry")
	    );
	    pm.currentTransaction().commit();
	}
	TransientObjectView view = new TransientObjectView(
		formValues,
		app,
		obj
	);
	HtmlPage p = HtmlPageFactory.openPage(
		view,
		request,
		out
	);
%>
<br />
<form id="<%= formName %>" name="<%= formName %>" accept-charset="UTF-8" action="<%= servletPath %>">
	<input type="hidden" name="<%= Action.PARAMETER_REQUEST_ID %>" value="<%= requestId %>" />
	<input type="hidden" name="<%= Action.PARAMETER_OBJECTXRI %>" value="<%= objectXri %>" />
	<input type="Hidden" id="Command" name="Command" value="" />	
	<table cellspacing="8" class="tableLayout">
		<tr>
			<td class="cellObject">
				<div class="panel" id="panel<%= formName %>" style="display: block">
<%
					form.paint(
						p,
						null, // frame
						true // forEditing
					);
					p.flush();
%>
					<div class="fieldGroupName">&nbsp;</div>
				</div>
				<input type="submit" class="abutton" name="Search" id="Search.Button" tabindex="9000" value="Search" onclick="javascript:$('Command').value=this.name" />
				<input type="button" class="abutton" onclick="javascript:new Ajax.Updater('UserDialog', '<%= servletPath + "?" + Action.PARAMETER_OBJECTXRI + "=" + java.net.URLEncoder.encode(accountSegment.refMofId(), "UTF-8") %>', {evalScripts: true});" value="New Search" />
<%
				if(account != null) {
%>
					<input type="button" class="abutton" onclick="javascript:new Ajax.Updater('UserDialog', '<%= servletPathPrefix + "CreateLeadWizard.jsp?" + Action.PARAMETER_OBJECTXRI + "=" + java.net.URLEncoder.encode(account.refMofId(), "UTF-8") %>', {evalScripts: true});" value="Create Lead" />
					<input type="button" class="abutton" onclick="javascript:new Ajax.Updater('UserDialog', '<%= servletPathPrefix + "CreateContractWizard.jsp?" + Action.PARAMETER_OBJECTXRI + "=" + java.net.URLEncoder.encode(account.refMofId(), "UTF-8") %>', {evalScripts: true});" value="Create Contract" />
					<input type="button" class="abutton" onclick="javascript:new Ajax.Updater('UserDialog', '<%= servletPathPrefix + "CreateActivityWizard.jsp?" + Action.PARAMETER_OBJECTXRI + "=" + java.net.URLEncoder.encode(account.refMofId(), "UTF-8") %>', {evalScripts: true});" value="Create Activity" />
					<input type="submit" class="abutton" name="OK" id="OK.Button" tabindex="9060" value="Apply Changes" onclick="javascript:$('Command').value=this.name;"/>
<%
				}
				else {
				    if(matchingContacts != null) {
%>
						<input type="submit" class="abutton" name="Create" id="Create.Button" tabindex="9070" value="Create New" onclick="javascript:$('Command').value=this.name;"/>
<%

				    }
				}
%>
				<input type="submit" class="abutton" name="Cancel" tabindex="9080" value="<%= app.getTexts().getCancelTitle() %>" onclick="javascript:$('Command').value=this.name;"/>
<%
				if(matchingContacts != null) {
%>
					<div>&nbsp;</div>
					<table class="gridTableFull">
						<tr class="gridTableHeaderFull">
							<td/>
							<td><%= view.getFieldLabel("org:opencrx:kernel:account1:Account", "fullName", app.getCurrentLocaleAsIndex()) %></td>
							<td><%= view.getFieldLabel("org:opencrx:kernel:account1:Account", "aliasName", app.getCurrentLocaleAsIndex()) %></td>
							<td><%= app.getLabel("org:opencrx:kernel:account1:PostalAddress") %></td>
							<td><%= app.getLabel("org:opencrx:kernel:account1:PostalAddress") %></td>
							<td><%= view.getFieldLabel("org:opencrx:kernel:account1:Account", "address*Business!phoneNumberFull", app.getCurrentLocaleAsIndex()) %></td>
							<td><%= view.getFieldLabel("org:opencrx:kernel:account1:Account", "address*Mobile!phoneNumberFull", app.getCurrentLocaleAsIndex()) %></td>
							<td><%= view.getFieldLabel("org:opencrx:kernel:account1:Account", "address*Business!emailAddress", app.getCurrentLocaleAsIndex()) %></td>
							<td><%= view.getFieldLabel("org:opencrx:kernel:account1:Contact", "organization", app.getCurrentLocaleAsIndex()) %></td>
							<td class="addon"/>
						</tr>
<%
					    int count = 0;
						for(Iterator i = matchingContacts.iterator(); i.hasNext(); ) {
						    org.opencrx.kernel.account1.jmi1.Contact contact = ( org.opencrx.kernel.account1.jmi1.Contact)i.next();
						    org.opencrx.kernel.account1.jmi1.AccountAddress[] addresses = Accounts.getInstance().getMainAddresses(contact);
%>
							<tr class="gridTableRowFull">
								<td><img style="cursor: pointer;" src="images/Contact.gif" onclick="javascript:new Ajax.Updater('UserDialog', '<%= servletPath + "?" + Action.PARAMETER_OBJECTXRI + "=" + java.net.URLEncoder.encode(contact.refMofId(), "UTF-8") %>', {evalScripts: true});"/></td>
								<td><%= contact.getFullName() == null ? "" : contact.getFullName() %></td>
								<td><%= contact.getAliasName() == null ? "" : contact.getAliasName() %></td>
								<td><%= new org.openmdx.portal.servlet.ObjectReference(addresses[Accounts.POSTAL_BUSINESS], app).getTitle() %></td>
								<td><%= new org.openmdx.portal.servlet.ObjectReference(addresses[Accounts.POSTAL_HOME], app).getTitle() %></td>
								<td><%= new org.openmdx.portal.servlet.ObjectReference(addresses[Accounts.PHONE_BUSINESS], app).getTitle() %></td>
								<td><%= new org.openmdx.portal.servlet.ObjectReference(addresses[Accounts.MOBILE], app).getTitle() %></td>
								<td><%= new org.openmdx.portal.servlet.ObjectReference(addresses[Accounts.MAIL_BUSINESS], app).getTitle() %></td>
								<td><%= contact.getOrganization() == null ? "" : contact.getOrganization() %></td>
								<td class="addon"/>
							</tr>
<%
							count++;
							if(count > 50) break;
						}
					}
%>
				</table>
			</td>
		</tr>
	</table>
</form>
<script language="javascript" type="text/javascript">
	Event.observe('<%= formName %>', 'submit', function(event) {
		$('<%= formName %>').request({
			onFailure: function() { },
			onSuccess: function(t) {
				$('UserDialog').update(t.responseText);
			}
		});
		Event.stop(event);
	});		
</script>