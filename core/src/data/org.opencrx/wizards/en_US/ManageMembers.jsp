﻿<%@  page contentType= "text/html;charset=utf-8" language="java" pageEncoding= "UTF-8" %>
<%@ page session="true" import="
java.util.*,
java.io.*,
java.text.*,
java.math.*,
java.net.*,
java.sql.*,
javax.naming.Context,
javax.naming.InitialContext,
org.openmdx.kernel.id.cci.*,
org.openmdx.kernel.id.*,
org.openmdx.base.accessor.jmi.cci.*,
org.openmdx.base.exception.*,
org.openmdx.portal.servlet.*,
org.openmdx.portal.servlet.attribute.*,
org.openmdx.portal.servlet.view.*,
org.openmdx.portal.servlet.texts.*,
org.openmdx.portal.servlet.control.*,
org.openmdx.portal.servlet.reports.*,
org.openmdx.portal.servlet.wizards.*,
org.openmdx.base.naming.*,
org.openmdx.base.query.*,
org.openmdx.kernel.log.*
" %><%
  final String WIZARD_NAME = "ManageMembers";
  final String FORMACTION   = WIZARD_NAME + ".jsp";
  request.setCharacterEncoding("UTF-8");
  ApplicationContext app = (ApplicationContext)session.getValue(WebKeys.APPLICATION_KEY);
  ViewsCache viewsCache = (ViewsCache)session.getValue(WebKeys.VIEW_CACHE_KEY_SHOW);
  String requestId =  request.getParameter(Action.PARAMETER_REQUEST_ID);
  String requestIdParam = Action.PARAMETER_REQUEST_ID + "=" + requestId;
  String objectXri = request.getParameter("xri");
  if(app == null || objectXri == null || viewsCache.getView(requestId) == null) {
      response.sendRedirect(
         request.getContextPath() + "/" + WebKeys.SERVLET_NAME
      );
      return;
  }
  javax.jdo.PersistenceManager pm = app.getNewPmData();
  Texts_1_0 texts = app.getTexts();
  org.openmdx.portal.servlet.Codes codes = app.getCodes();
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>

<head>
  <title>Manage Members</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="label" content="Manage Members">
  <meta name="toolTip" content="Manage Members">
  <meta name="targetType" content="_blank">
  <meta name="forClass" content="org:opencrx:kernel:account1:Contact">
  <meta name="forClass" content="org:opencrx:kernel:account1:LegalEntity">
  <meta name="forClass" content="org:opencrx:kernel:account1:Group">
  <meta name="forClass" content="org:opencrx:kernel:account1:UnspecifiedAccount">
  <meta name="order" content="9102">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <link href="../../_style/n2default.css" rel="stylesheet" type="text/css">
  <link href="../../_style/ssf.css" rel="stylesheet" type="text/css">
  <link href="../../_style/colors.css" rel="stylesheet" type="text/css">
  <!--[if lt IE 7]><script type="text/javascript" src="../../javascript/iehover-fix.js"></script><![endif]-->
  <script language="javascript" type="text/javascript" src="../../javascript/portal-all.js"></script>
  <link rel="shortcut icon" href="../../images/favicon.ico" />
</head>

<style type="text/css" media="all">
  .gridTableRowFull TD {white-space:nowrap;}
  .gridTableHeaderFull TD {white-space:nowrap;vertical-align:bottom;}
</style>

<body>
<div id="container">
	<div id="wrap">
		<div id="header" style="height:90px;">
      <div id="logoTable">
        <table id="headerlayout">
          <tr id="headRow">
            <td id="head" colspan="2">
              <table id="info">
                <tr>
                  <td id="headerCellLeft"><img id="logoLeft" src="../../images/logoLeft.gif" alt="openCRX" title="" /></td>
                  <td id="headerCellSpacerLeft"></td>
                  <td id="headerCellMiddle">&nbsp;</td>
                  <td id="headerCellRight"><img id="logoRight" src="../../images/logoRight.gif" alt="" title="" /></td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </div>
    </div>

    <div id="content-wrap">
    	<div id="content" style="padding:100px 0.5em 0px 0.5em;">
<%
    NumberFormat formatter = new DecimalFormat("0");

    // Format dates/times
    TimeZone timezone = TimeZone.getTimeZone(app.getCurrentTimeZone());
    SimpleDateFormat timeFormat = new SimpleDateFormat("dd-MMM-yyyy HH:mm", app.getCurrentLocale());
    timeFormat.setTimeZone(timezone);

    final String MEMBER_CLASS = "org:opencrx:kernel:account1:Member";
    final String MEMBERSHIP_CLASS = "org:opencrx:kernel:account1:AccountMembership";
    final String ACCOUNTSEGMENT_CLASS = "org:opencrx:kernel:account1:Segment";
    final String ACCOUNT_CLASS = "org:opencrx:kernel:account1:Account";
    final String ACCOUNTFILTERGLOBAL_CLASS = "org:opencrx:kernel:account1:AccountFilterGlobal";
    final String CONTACT_CLASS = "org:opencrx:kernel:account1:Contact";
    final String LEGALENTITY_CLASS = "org:opencrx:kernel:account1:LegalEntity";
    final String GROUP_CLASS = "org:opencrx:kernel:account1:Group";
    final String UNSPECIFIEDACCOUNT_CLASS = "org:opencrx:kernel:account1:UnspecifiedAccount";
    final String EMAILADDRESS_CLASS = "org:opencrx:kernel:account1:EMailAddress";
    final String POSTALADDRESS_CLASS = "org:opencrx:kernel:account1:PostalAddress";

    final String ACCOUNT_FILTER_XRI_PREFIX = "ACCOUNT_FILTER_XRI_";

    final int DEFAULT_PAGE_SIZE = 20;

    final String colorDuplicate = "#FFA477";
    final String colorMember = "#D2FFD2";
    final String colorMemberDisabled = "#F2F2F2";

    final String CAUTION = "<img border='0' alt='' height='16px' src='../../images/caution.gif' />";

    String errorMsg = "";

    try {
      // get reference of calling object
      RefObject_1_0 obj = (RefObject_1_0)pm.getObjectById(new Path(objectXri));

      Path objectPath = new Path(objectXri);
      String providerName = objectPath.get(2);
      String segmentName = objectPath.get(4);

      UserDefinedView userView = new UserDefinedView(
        obj,
        app,
        viewsCache.getView(requestId)
      );

      // Get account1 package
      org.opencrx.kernel.account1.jmi1.Account1Package accountPkg = org.opencrx.kernel.utils.Utils.getAccountPackage(pm);

      // Get account segment
      org.opencrx.kernel.account1.jmi1.Segment accountSegment =
        (org.opencrx.kernel.account1.jmi1.Segment)pm.getObjectById(
          new Path("xri:@openmdx:org.opencrx.kernel.account1/provider/" + providerName + "/segment/" + segmentName)
         );

      org.opencrx.kernel.account1.jmi1.Account accountSource = null;
      String accountTitle = "";
      if (obj instanceof org.opencrx.kernel.account1.jmi1.Account) {
          accountSource = (org.opencrx.kernel.account1.jmi1.Account)obj;
          accountTitle = (new ObjectReference(accountSource, app)).getTitle();
      }

      org.opencrx.kernel.account1.cci2.AccountQuery accountFilter = accountPkg.createAccountQuery();
      accountFilter.forAllDisabled().isFalse();
      accountFilter.orderByFullName().ascending();

      org.opencrx.kernel.account1.cci2.ContactQuery contactFilter = accountPkg.createContactQuery();
      contactFilter.forAllDisabled().isFalse();
      contactFilter.orderByFullName().ascending();

      org.opencrx.kernel.account1.cci2.LegalEntityQuery legalEntityFilter = accountPkg.createLegalEntityQuery();
      legalEntityFilter.forAllDisabled().isFalse();
      legalEntityFilter.orderByFullName().ascending();

      org.opencrx.kernel.account1.cci2.GroupQuery groupFilter = accountPkg.createGroupQuery();
      groupFilter.forAllDisabled().isFalse();
      groupFilter.orderByFullName().ascending();

      org.opencrx.kernel.account1.cci2.UnspecifiedAccountQuery unspecifiedAccountFilter = accountPkg.createUnspecifiedAccountQuery();
      unspecifiedAccountFilter.forAllDisabled().isFalse();
      unspecifiedAccountFilter.orderByFullName().ascending();

      org.opencrx.kernel.account1.cci2.MemberQuery memberFilter = accountPkg.createMemberQuery();
      memberFilter.orderByCreatedAt().ascending();

      int tabIndex = 1;
      int pageSize = DEFAULT_PAGE_SIZE;
      int displayStart = 0;
      long highAccount = 0;
      boolean isFirstCall = request.getParameter("isFirstCall") == null; // used to properly initialize various options
      boolean highAccountIsKnown = ((request.getParameter("highAccountIsKnown") != null) && (request.getParameter("highAccountIsKnown").length() > 0));
      boolean isSelectionChange = isFirstCall || request.getParameter("isSelectionChange") != null;
      String accountFilterXri = null;
      org.opencrx.kernel.account1.jmi1.AccountFilterGlobal selectedAccountFilterGlobal = null;
      int accountSelectorType = 0;
      if (request.getParameter("accountSelectorType") != null && !request.getParameter("accountSelectorType").startsWith(ACCOUNT_FILTER_XRI_PREFIX)) {
          try {
              accountSelectorType = Integer.parseInt(request.getParameter("accountSelectorType"));
          } catch (Exception e) {}
      } else if (request.getParameter("accountSelectorType") != null && request.getParameter("accountSelectorType").startsWith(ACCOUNT_FILTER_XRI_PREFIX)) {
          accountFilterXri = request.getParameter("accountSelectorType").substring(ACCOUNT_FILTER_XRI_PREFIX.length());
          try {
              selectedAccountFilterGlobal = (org.opencrx.kernel.account1.jmi1.AccountFilterGlobal)pm.getObjectById(new Path(accountFilterXri));
              accountSelectorType = 2;
          } catch (Exception e) {}
      }
      boolean membersOnly = accountSelectorType == 1;
      boolean detectDuplicates = ((request.getParameter("detectDuplicates") != null) && (request.getParameter("detectDuplicates").length() > 0));
      boolean selectAccount = false;
      boolean selectContact = false;
      boolean selectLegalEntity = false;
      boolean selectGroup = false;
      boolean selectUnspecifiedAccount = false;
      if (membersOnly) {
          selectAccount = true;
      } else {
          if (request.getParameter("accountSelector") != null) {
              selectContact =            request.getParameter("accountSelector").compareTo("selectContact") == 0;
              selectLegalEntity =        request.getParameter("accountSelector").compareTo("selectLegalEntity") == 0;
              selectGroup =              request.getParameter("accountSelector").compareTo("selectGroup") == 0;
              selectUnspecifiedAccount = request.getParameter("accountSelector").compareTo("selectUnspecifiedAccount") == 0;
          }
      }
      try {
        pageSize = request.getParameter("pageSize") != null ? Integer.parseInt(request.getParameter("pageSize")) : DEFAULT_PAGE_SIZE;
      } catch (Exception e) {}
      try {
        highAccount = request.getParameter("highAccount") != null ? Long.parseLong(request.getParameter("highAccount")) : 0;
      } catch (Exception e) {}
      try {
        if (request.getParameter("displayStart") != null && request.getParameter("displayStart").startsWith("+")) {
          displayStart = ((int)((highAccount + Long.parseLong(request.getParameter("displayStart").substring(1))) / (long)pageSize)) - 1;
          if (displayStart < 0) {
            displayStart = 0;
          }
        } else {
          displayStart = request.getParameter("displayStart") != null ? Integer.parseInt(request.getParameter("displayStart")) : 0;
        }
      } catch (Exception e) {}
      if (isSelectionChange) {
         highAccount = 0;
         displayStart = 0;
         highAccountIsKnown = false;
      }

      if (request.getParameter("Reload.Button") != null) {
          //System.out.println("reload.button");
          //app.resetPmData(); // evict pm data, i.e. clear cache
      }

      Iterator accounts = null;
      long counter = 0;
      boolean iteratorNotSet = true;
      int itSetCounter = 0;
      final int MAXITSETCOUNTER = 2;
      while (iteratorNotSet && itSetCounter < MAXITSETCOUNTER) {
          itSetCounter++;
          try {
              if (selectContact) {
                  if (accountSelectorType == 0) {
                      accounts = accountSegment.getAccount(contactFilter).listIterator((int)displayStart*pageSize);
                  } else {
                      accounts = selectedAccountFilterGlobal.getFilteredAccount(contactFilter).listIterator((int)displayStart*pageSize);
                  }
              } else if (selectLegalEntity) {
                  if (accountSelectorType == 0) {
                      accounts = accountSegment.getAccount(legalEntityFilter).listIterator((int)displayStart*pageSize);
                  } else {
                      accounts = selectedAccountFilterGlobal.getFilteredAccount(legalEntityFilter).listIterator((int)displayStart*pageSize);
                  }
              } else if (selectGroup) {
                  if (accountSelectorType == 0) {
                      accounts = accountSegment.getAccount(groupFilter).listIterator((int)displayStart*pageSize);
                  } else {
                      accounts = selectedAccountFilterGlobal.getFilteredAccount(groupFilter).listIterator((int)displayStart*pageSize);
                  }
              } else if (selectUnspecifiedAccount) {
                  if (accountSelectorType == 0) {
                      accounts = accountSegment.getAccount(unspecifiedAccountFilter).listIterator((int)displayStart*pageSize);
                  } else {
                      accounts = selectedAccountFilterGlobal.getFilteredAccount(unspecifiedAccountFilter).listIterator((int)displayStart*pageSize);
                  }
              } else {
                  selectAccount = true;
                  if (accountSelectorType == 0) {
                      accounts = accountSegment.getAccount(accountFilter).listIterator((int)displayStart*pageSize);
                  } else if (accountSelectorType == 1) {
                      // membersOnly
                      accounts = (accountSource.getMember(memberFilter)).listIterator((int)displayStart*pageSize);
                  } else if (accountSelectorType == 2) {
                      accounts = selectedAccountFilterGlobal.getFilteredAccount(accountFilter).listIterator((int)displayStart*pageSize);
                  }
              }
              counter = displayStart*pageSize;
              if (!accounts.hasNext()) {
                  displayStart = (int)((highAccount / (long)pageSize));
                  counter = displayStart*pageSize;
              } else {
                iteratorNotSet = false;
              }
          } catch (Exception e) {
              new ServiceException(e).log();
              displayStart = 0;
              counter = 0;
          }
      }

      if (request.getParameter("ACTION.create") != null) {
          //System.out.println("CREATE: " + request.getParameter("ACTION.create"));
          if (accountSource != null) {
              try {
                  pm.currentTransaction().begin();
                  org.opencrx.kernel.account1.jmi1.Account accountTarget = (org.opencrx.kernel.account1.jmi1.Account)pm.getObjectById(new Path((request.getParameter("ACTION.create"))));
                  org.opencrx.kernel.account1.jmi1.Member newMember = accountPkg.getMember().createMember();
                  newMember.refInitialize(false, false);
                  //newMember.setMemberRole(new short[]{MEMBERROLESALESREGION});
                  newMember.setValidFrom(new java.util.Date());
                  newMember.setAccount(accountTarget);
                  newMember.setQuality((short)5);
                  newMember.setName(accountTarget.getFullName());
                  accountSource.addMember(
                    false,
                    org.opencrx.kernel.backend.Accounts.getInstance().getUidAsString(),
                    newMember
                  );
                  pm.currentTransaction().commit();
              } catch (Exception e) {
                  errorMsg = "Cannot enable " + app.getLabel(MEMBER_CLASS);
                  new ServiceException(e).log();
                  try {
                      pm.currentTransaction().rollback();
                  } catch (Exception er) {}
              }
          } else {
              errorMsg = "Cannot create " + app.getLabel(MEMBER_CLASS) + " [parent missing]";
          }
      } else if (request.getParameter("ACTION.enable") != null) {
          //System.out.println("ENABLE: " + request.getParameter("ACTION.enable"));
          try {
              pm.currentTransaction().begin();
              org.opencrx.kernel.account1.jmi1.Member member = (org.opencrx.kernel.account1.jmi1.Member)pm.getObjectById(new Path((request.getParameter("ACTION.enable"))));
              member.setDisabled(new Boolean(false));
              if (member.getValidFrom() == null) {
                  member.setValidFrom(new java.util.Date());
              }
              member.setValidTo(null);
              if ((member.getName() == null || member.getName().length() == 0) && member.getAccount() != null) {
                  member.setName(member.getAccount().getFullName());
              }
              pm.currentTransaction().commit();
          } catch (Exception e) {
              errorMsg = "Cannot enable " + app.getLabel(MEMBER_CLASS);
              new ServiceException(e).log();
              try {
                  pm.currentTransaction().rollback();
              } catch (Exception er) {}
          }
      } else if (request.getParameter("ACTION.disable") != null) {
          //System.out.println("DISABLE: " + request.getParameter("ACTION.disable"));
          try {
              pm.currentTransaction().begin();
              org.opencrx.kernel.account1.jmi1.Member member = (org.opencrx.kernel.account1.jmi1.Member)pm.getObjectById(new Path((request.getParameter("ACTION.disable"))));
              member.setDisabled(new Boolean(true));
              member.setValidTo(new java.util.Date());
              if ((member.getName() == null || member.getName().length() == 0) && member.getAccount() != null) {
                  member.setName(member.getAccount().getFullName());
              }
              pm.currentTransaction().commit();
          } catch (Exception e) {
              errorMsg = "Cannot disable " + app.getLabel(MEMBER_CLASS);
              new ServiceException(e).log();
              try {
                  pm.currentTransaction().rollback();
              } catch (Exception er) {}
          }
      } else if (request.getParameter("ACTION.delete") != null) {
          //System.out.println("DELETE: " + request.getParameter("ACTION.delete"));
          try {
              pm.currentTransaction().begin();
              org.opencrx.kernel.account1.jmi1.Member member = (org.opencrx.kernel.account1.jmi1.Member)pm.getObjectById(new Path((request.getParameter("ACTION.delete"))));
              ((RefObject_1_0)member).refDelete();
              pm.currentTransaction().commit();
          } catch (Exception e) {
              errorMsg = "Cannot delete " + app.getLabel(MEMBER_CLASS);
              new ServiceException(e).log();
              try {
                  pm.currentTransaction().rollback();
              } catch (Exception er) {}
          }
      }
%>
      <div id="etitle" style="height:20px;">
         Manage Members of "<%= accountTitle %>"
      </div>
      <form name="ManageMembers" accept-charset="UTF-8" method="POST" action="<%= FORMACTION %>">
        <input type="hidden" name="<%= Action.PARAMETER_OBJECTXRI %>" value="<%= objectXri %>" />
        <input type="hidden" name="<%= Action.PARAMETER_REQUEST_ID %>" value="<%= requestId %>" />
        <input type="checkbox" style="display:none;" name="isFirstCall" checked />
        <input type="checkbox" style="display:none;" name="isSelectionChange" id="isSelectionChange" />
        <br />

        <table class="fieldGroup">
          <tr>
            <td id="submitButtons" style="font-weight:bold;">
              <div style="background-color:#eee;padding:3px;">
                <%= app.getTexts().getSelectAllText() %> <select id="accountSelectorType" name="accountSelectorType" onchange="javascript:$('waitMsg').style.visibility='visible';$('submitButtons').style.visibility='hidden';$('isSelectionChange').checked=true;$('Reload.Button').click();" >
                  <option <%= accountSelectorType == 0 ? "selected" : "" %> value="0">* <%= app.getLabel(ACCOUNTSEGMENT_CLASS) %>&nbsp;</option>
                  <option <%= accountSelectorType == 1 ? "selected" : "" %> value="1"><%= app.getLabel(MEMBER_CLASS)  %>&nbsp;</option>
<%
									org.opencrx.kernel.account1.cci2.AccountFilterGlobalQuery accountFilterGlobalQuery = (org.opencrx.kernel.account1.cci2.AccountFilterGlobalQuery)pm.newQuery(org.opencrx.kernel.account1.jmi1.AccountFilterGlobal.class);
									accountFilterGlobalQuery.forAllDisabled().isFalse();
									accountFilterGlobalQuery.orderByName().ascending();
									for(Iterator i = accountSegment.getAccountFilter(accountFilterGlobalQuery).iterator(); i.hasNext(); ) {
									    org.opencrx.kernel.account1.jmi1.AccountFilterGlobal accountFilterGlobal = (org.opencrx.kernel.account1.jmi1.AccountFilterGlobal)i.next();
%>
                      <option <%= (accountSelectorType == 2) && (accountFilterXri != null && accountFilterXri.compareTo(accountFilterGlobal.refMofId()) == 0) ? "selected" : "" %> value="<%= ACCOUNT_FILTER_XRI_PREFIX %><%= accountFilterGlobal.refMofId() %>"><%= app.getLabel(ACCOUNTFILTERGLOBAL_CLASS) %>: <%= accountFilterGlobal.getName() != null ? accountFilterGlobal.getName() : "?" %> &nbsp;</option>
<%
									}
%>
                </select>&nbsp;
<%
                if (!membersOnly) {
%>
                    &nbsp;&nbsp;<input type="radio" name="accountSelector" <%= selectAccount            ? "checked" : "" %> value="selectAccount"            onchange="javascript:setTimeout('disableSubmit()', 10);$('isSelectionChange').checked=true;$('Reload.Button').click();" /> *
                    &nbsp;&nbsp;<input type="radio" name="accountSelector" <%= selectContact            ? "checked" : "" %> value="selectContact"            onchange="javascript:setTimeout('disableSubmit()', 10);$('isSelectionChange').checked=true;$('Reload.Button').click();" /> <%= app.getLabel(CONTACT_CLASS) %>
                    &nbsp;&nbsp;<input type="radio" name="accountSelector" <%= selectLegalEntity        ? "checked" : "" %> value="selectLegalEntity"        onchange="javascript:setTimeout('disableSubmit()', 10);$('isSelectionChange').checked=true;$('Reload.Button').click();" /> <%= app.getLabel(LEGALENTITY_CLASS) %>
                    &nbsp;&nbsp;<input type="radio" name="accountSelector" <%= selectGroup              ? "checked" : "" %> value="selectGroup"              onchange="javascript:setTimeout('disableSubmit()', 10);$('isSelectionChange').checked=true;$('Reload.Button').click();" /> <%= app.getLabel(GROUP_CLASS) %>
                    &nbsp;&nbsp;<input type="radio" name="accountSelector" <%= selectUnspecifiedAccount ? "checked" : "" %> value="selectUnspecifiedAccount" onchange="javascript:setTimeout('disableSubmit()', 10);$('isSelectionChange').checked=true;$('Reload.Button').click();" /> <%= app.getLabel(UNSPECIFIEDACCOUNT_CLASS) %>
<%
                }
%>
              </div>
                <br />
                <a href="#" onclick="javascript:try{($('displayStart').value)--}catch(e){};$('Reload.Button').click();" onmouseup="javascript:setTimeout('disableSubmit()', 10);" ><img border="0" align="top" alt="&lt;" src="../../images/previous.gif" style="padding-top:5px;"></a>
                <span id="displayStartSelector">...</span>
                <a href="#" onclick="javascript:try{($('displayStart').value)++}catch(e){};$('Reload.Button').click();" onmouseup="javascript:setTimeout('disableSubmit()', 10);" ><img border="0" align="top" alt="&lt;" src="../../images/next.gif" style="padding-top:5px;"></a>
                &nbsp;&nbsp;&nbsp;
                <select id="pageSize" name="pageSize" style="text-align:right;" onchange="javascript:$('waitMsg').style.visibility='visible';$('submitButtons').style.visibility='hidden';$('isSelectionChange').checked=true;$('Reload.Button').click();" >
                  <option <%= pageSize ==  10 ? "selected" : "" %> value="10">10&nbsp;</option>
                  <option <%= pageSize ==  20 ? "selected" : "" %> value="20">20&nbsp;</option>
                  <option <%= pageSize ==  50 ? "selected" : "" %> value="50">50&nbsp;</option>
                  <option <%= pageSize == 100 ? "selected" : "" %> value="100">100&nbsp;</option>
                  <option <%= pageSize == 500 ? "selected" : "" %> value="500">500&nbsp;</option>
                </select>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <input type="checkbox" name="detectDuplicates" id="detectDuplicates" <%= detectDuplicates ? "checked" : "" %> /> Detect Duplicates
                &nbsp;&nbsp;
                <INPUT type="Submit" id="Reload.Button" name="Reload.Button" tabindex="<%= tabIndex++ %>" value="<%= app.getTexts().getReloadText() %>" onmouseup="javascript:setTimeout('disableSubmit()', 10);" />
                <!-- <INPUT type="Submit" id="DetectDuplicates.Button" name="DetectDuplicates.Button" tabindex="<%= tabIndex++ %>" value="Detect Duplicates" onmouseup="javascript:setTimeout('disableSubmit()', 10);" /> -->
                <INPUT type="Submit" name="Print.Button" tabindex="<%= tabIndex++ %>" value="Print" onClick="javascript:window.print();return false;" />
                <INPUT type="Submit" name="Cancel.Button" tabindex="<%= tabIndex++ %>" value="<%= app.getTexts().getCancelTitle() %>" onClick="javascript:window.close();" />

            </td>
            <td id="waitMsg" style="display:none;">
              <div style="padding-left:5px; padding-bottom: 48px;">
                <img src="../../images/wait.gif" alt="" />
              </div>
            </td>
          </tr>
        </table>
<%
		if (errorMsg.length() > 0) {
%>
			<div style="background-color:red;color:white;border:1px solid black;padding:10px;font-weight:bold;margin-top:10px;">
				<%= errorMsg %>
			</div>
<%
		}
%>
        <br />

        <table><tr><td>
        <table id="resultTable" class="gridTableFull">
          <tr class="gridTableHeaderFull"><!-- 10 columns -->
            <td align="right">
              <a href="#" onclick="javascript:try{($('displayStart').value)--}catch(e){};$('Reload.Button').click();" onmouseup="javascript:setTimeout('disableSubmit()', 10);" ><img border="0" align="top" alt="&lt;" src="../../images/previous.gif"></a>
              #
              <a href="#" onclick="javascript:try{($('displayStart').value)++}catch(e){};$('Reload.Button').click();" onmouseup="javascript:setTimeout('disableSubmit()', 10);" ><img border="0" align="top" alt="&lt;" src="../../images/next.gif"></a></td>
            <td align="left">&nbsp;<b><%= app.getLabel(ACCOUNT_CLASS) %></b></td>
            <td align="left">&nbsp;<b><%= app.getLabel(EMAILADDRESS_CLASS) %></b></td>
            <td align="left">&nbsp;<b><%= app.getLabel(POSTALADDRESS_CLASS) %></b></td>
            <td align="left" nowrap>
               <!-- <img src="../../images/NumberReplacement.gif" alt="" align="top" /> -->
               <INPUT type="submit" name="addvisible"     id="addvisible"     title="add/enable visible" tabindex="<%= tabIndex++ %>" value="+"       onclick="javascript:$('executemulti').style.visibility='visible';$('executemulti').name=this.name;$('disablevisible').style.display='none';$('deletevisible').style.display='none';return false;" onmouseup="this.style.border='3px solid red';" style="font-size:10px;font-weight:bold;" />
               <INPUT type="submit" name="disablevisible" id="disablevisible" title="disable visible"    tabindex="<%= tabIndex++ %>" value="&ndash;" onclick="javascript:$('executemulti').style.visibility='visible';$('executemulti').name=this.name;$('addvisible').style.display='none';$('deletevisible').style.display='none';return false;"     onmouseup="this.style.border='3px solid red';" style="font-size:10px;font-weight:bold;" />
               <INPUT type="submit" name="deletevisible"  id="deletevisible"  title="delete visible"     tabindex="<%= tabIndex++ %>" value="X"       onclick="javascript:$('executemulti').style.visibility='visible';$('executemulti').name=this.name;$('addvisible').style.display='none';$('disablevisible').style.display='none';return false;"    onmouseup="this.style.border='3px solid red';" style="font-size:10px;font-weight:bold;" />
               <INPUT type="submit" name="executemulti"   id="executemulti"   title="<%= app.getTexts().getOkTitle() %>" style="visibility:hidden;" tabindex="<%= tabIndex++ %>" value="<%= app.getTexts().getOkTitle() %>" onmouseup="javascript:setTimeout('disableSubmit()', 10);$('addvisible').style.display='none';$('disablevisible').style.display='none';$('deletevisible').style.display='none';this.style.display='none';this.name='ACTION.'+this.name;" style="font-size:10px;font-weight:bold;" /><br>
               <b><%= app.getLabel(MEMBERSHIP_CLASS) %></b>
            </td>
            <td align="center">&nbsp;<b><%= userView.getFieldLabel(MEMBER_CLASS, "memberRole", app.getCurrentLocaleAsIndex()) %></b></td>
            <td align="center">&nbsp;<b><%= userView.getFieldLabel(MEMBER_CLASS, "validFrom", app.getCurrentLocaleAsIndex()) %></b></td>
            <td align="center">&nbsp;<b><%= userView.getFieldLabel(MEMBER_CLASS, "validTo", app.getCurrentLocaleAsIndex()) %></b></td>
            <td align="center"><b><%= userView.getFieldLabel(MEMBER_CLASS, "name", app.getCurrentLocaleAsIndex()) != null ? userView.getFieldLabel(MEMBER_CLASS, "name", app.getCurrentLocaleAsIndex()) : "" %></b></td>
            <td align="center"><b><%= userView.getFieldLabel(MEMBER_CLASS, "description", app.getCurrentLocaleAsIndex()) %></b></td>
          </tr>
<%
          if (accounts != null) {
              for(
                Iterator i = accounts;
                i.hasNext() && (counter <= (displayStart+1)*pageSize);
              ) {
                  org.opencrx.kernel.account1.jmi1.Account account = null;
                  org.opencrx.kernel.generic.jmi1.CrxObject crxObject = (org.opencrx.kernel.generic.jmi1.CrxObject)i.next();
                  if (crxObject instanceof org.opencrx.kernel.account1.jmi1.Account) {
                      account = (org.opencrx.kernel.account1.jmi1.Account)crxObject;
                  } else {
                      account = ((org.opencrx.kernel.account1.jmi1.Member)crxObject).getAccount();
                      if (account == null) {
                          continue;
                      }
                  }
                  if (!i.hasNext()) {
                      highAccountIsKnown = true;
                      highAccount = counter+1;
                  }
                  counter++;
                  if (counter < displayStart*pageSize || counter > (displayStart+1)*pageSize) {
                    continue;
                  }

                  String accountHref = "";
                  Action action = new ObjectReference(
                      account,
                      app
                  ).getSelectObjectAction();
                  accountHref = "../../" + action.getEncodedHRef();

                  String image = "Contact.gif";
                  String label = app.getLabel("org:opencrx:kernel:account1:Contact");
                  if (account instanceof org.opencrx.kernel.account1.jmi1.UnspecifiedAccount) {
                    image = "UnspecifiedAccount.gif";
                    label = app.getLabel("org:opencrx:kernel:account1:UnspecifiedAccount");
                  }
                  if (account instanceof org.opencrx.kernel.account1.jmi1.LegalEntity) {
                    image = "LegalEntity.gif";
                    label = app.getLabel("org:opencrx:kernel:account1:LegalEntity");
                  }
                  if (account instanceof org.opencrx.kernel.account1.jmi1.Group) {
                    image = "Group.gif";
                    label = app.getLabel("org:opencrx:kernel:account1:Group");
                  }

                  // get all (not disabled) EMailAddresses of this account
                  SortedSet<String> eMailAddresses = new TreeSet<String>();
                  org.opencrx.kernel.account1.cci2.EMailAddressQuery eMailAddressFilter = accountPkg.createEMailAddressQuery();
                  eMailAddressFilter.forAllDisabled().isFalse();
                  for (
                    Iterator a = account.getAddress(eMailAddressFilter).iterator();
                    a.hasNext();
                  ) {
                      org.opencrx.kernel.account1.jmi1.EMailAddress addr = (org.opencrx.kernel.account1.jmi1.EMailAddress)a.next();
                      if (addr.getEmailAddress() != null && addr.getEmailAddress().length() > 0) {
                          // add this address to list
                          eMailAddresses.add(addr.getEmailAddress());
                      }
                  }

                  // get Postaladdresses of this account (business if available, otherwise private, otherwise any postal address
                  org.opencrx.kernel.account1.jmi1.PostalAddress businessAddr = null;
                  org.opencrx.kernel.account1.jmi1.PostalAddress homeAddr = null;
                  org.opencrx.kernel.account1.jmi1.PostalAddress otherAddr = null;
                  org.opencrx.kernel.account1.jmi1.PostalAddress infoAddr = null;
                  org.opencrx.kernel.account1.cci2.PostalAddressQuery addressFilter = accountPkg.createPostalAddressQuery();
                  addressFilter.forAllDisabled().isFalse();
                  for (
                    Iterator a = account.getAddress(addressFilter).iterator();
                    a.hasNext();
                  ) {
                    org.opencrx.kernel.account1.jmi1.PostalAddress addr = (org.opencrx.kernel.account1.jmi1.PostalAddress)a.next();
                    for(
                        Iterator k = addr.getUsage().iterator();
                        k.hasNext();
                    ) {
                        switch (((Number)k.next()).intValue()) {
                            case  400:  homeAddr = addr; break;
                            case  500:  businessAddr = addr; break;
                            default  :  otherAddr = addr; break;
                        }
                    }
                  }
                  if (businessAddr != null) {
                    infoAddr = businessAddr;
                  } else if (homeAddr != null) {
                    infoAddr = homeAddr;
                  } else if (otherAddr != null) {
                    infoAddr = otherAddr;
                  }
                  String addressInfo = "";
                  if (infoAddr != null) {
                    if (infoAddr.getPostalCode() != null) {addressInfo += infoAddr.getPostalCode() + " ";}
                    if (infoAddr.getPostalCity() != null) {addressInfo += infoAddr.getPostalCity();}
                  }

                  int memberCounter = 0;
                  String memberHref = "";
                  org.opencrx.kernel.account1.jmi1.Member member = null;
                  org.opencrx.kernel.account1.cci2.MemberQuery isMemberFilter = accountPkg.createMemberQuery();
                  isMemberFilter.thereExistsAccount().equalTo(account);
                  for(Iterator m = accountSource.getMember(isMemberFilter).iterator(); m.hasNext(); ) {
                      try {
                          memberCounter++;
                          org.opencrx.kernel.account1.jmi1.Member currentMember = (org.opencrx.kernel.account1.jmi1.Member)m.next();
                          if (member == null || currentMember.isDisabled() == null || !currentMember.isDisabled().booleanValue()) {
                              member = currentMember;
                              action = new ObjectReference(
                                  currentMember,
                                  app
                              ).getSelectObjectAction();
                              memberHref = "../../" + action.getEncodedHRef();
                          }
                      } catch (Exception e) {}
                  }
                  if (member == null && request.getParameter("ACTION.addvisible") != null) {
                      // create new member
                      if (accountSource != null) {
                          try {
                              pm.currentTransaction().begin();
                              org.opencrx.kernel.account1.jmi1.Account accountTarget = account;
                              org.opencrx.kernel.account1.jmi1.Member newMember = accountPkg.getMember().createMember();
                              newMember.refInitialize(false, false);
                              //newMember.setMemberRole(new short[]{0});
                              newMember.setValidFrom(new java.util.Date());
                              newMember.setAccount(accountTarget);
                              newMember.setQuality((short)5);
                              newMember.setName(accountTarget.getFullName());
                              accountSource.addMember(
                                false,
                                org.opencrx.kernel.backend.Accounts.getInstance().getUidAsString(),
                                newMember
                              );
                              pm.currentTransaction().commit();
                              member = newMember;
                          } catch (Exception e) {
                              errorMsg = "Cannot create " + app.getLabel(MEMBER_CLASS);
                              new ServiceException(e).log();
                              try {
                                  pm.currentTransaction().rollback();
                              } catch (Exception er) {}
                          }
                      } else {
                          errorMsg = "Cannot create " + app.getLabel(MEMBER_CLASS) + " [parent missing]";
                      }
                  }
                  if (member != null && member.isDisabled() != null && member.isDisabled().booleanValue() && request.getParameter("ACTION.addvisible") != null) {
                      // enable existing member
                      try {
                          pm.currentTransaction().begin();
                          member.setDisabled(new Boolean(false));
                          if (member.getValidFrom() == null) {
                              member.setValidFrom(new java.util.Date());
                          }
                          member.setValidTo(null);
                          if ((member.getName() == null || member.getName().length() == 0) && member.getAccount() != null) {
                              member.setName(member.getAccount().getFullName());
                          }
                          pm.currentTransaction().commit();
                      } catch (Exception e) {
                          errorMsg = "Cannot enable " + app.getLabel(MEMBER_CLASS);
                          new ServiceException(e).log();
                          try {
                              pm.currentTransaction().rollback();
                          } catch (Exception er) {}
                      }
                  }
                  if (member != null && request.getParameter("ACTION.disablevisible") != null) {
                      try {
                          pm.currentTransaction().begin();
                          member.setDisabled(new Boolean(true));
                          member.setValidTo(new java.util.Date());
                          if ((member.getName() == null || member.getName().length() == 0) && member.getAccount() != null) {
                              member.setName(member.getAccount().getFullName());
                          }
                          pm.currentTransaction().commit();
                      } catch (Exception e) {
                          errorMsg = "Cannot disable " + app.getLabel(MEMBER_CLASS);
                          new ServiceException(e).log();
                          try {
                              pm.currentTransaction().rollback();
                          } catch (Exception er) {}
                      }
                  }
                  if (member != null && (request.getParameter("ACTION.deletevisible") != null || request.getParameter("ACTION.deletevisible") != null)) {
                      try {
                          pm.currentTransaction().begin();
                          ((RefObject_1_0)member).refDelete();
                          pm.currentTransaction().commit();
                          member = null;
                      } catch (Exception e) {
                          errorMsg = "Cannot delete " + app.getLabel(MEMBER_CLASS);
                          new ServiceException(e).log();
                          try {
                              pm.currentTransaction().rollback();
                          } catch (Exception er) {}
                      }
                  }

                  boolean isMember = member != null;
                  boolean isDisabled = member != null && member.isDisabled() != null && member.isDisabled().booleanValue();
                  String memberRoles = "";
                  if (member != null) {
                      for(
                          Iterator r = member.getMemberRole().iterator();
                          r.hasNext();
                      ) {
                          memberRoles += (String)(codes.getLongText("org:opencrx:kernel:account1:Member:memberRole", app.getCurrentLocaleAsIndex(), true, true).get(new Short((Short)r.next()))) + "<br />";
                      }
                      if ((member.getName() == null || member.getName().length() == 0) && member.getAccount() != null) {
                          // set member.name (a mandatory attribute)
                          try {
                              pm.currentTransaction().begin();
                              member.setName(member.getAccount().getFullName());
                              pm.currentTransaction().commit();
                          } catch (Exception e) {
                              new ServiceException(e).log();
                              try {
                                  pm.currentTransaction().rollback();
                              } catch (Exception er) {}
                          }
                      }

                  }
%>
                  <tr class="gridTableRowFull" style="<%= isMember ? "background-color:" + (isDisabled ? colorMemberDisabled + ";font-style:italic" : colorMember + ";font-weight:bold") : "" %>;"><!-- 8 columns -->
                    <td align="right"><%= isMember ? "<a href='" + memberHref + "' target='_blank'>" : "" %><%= formatter.format(counter) %><%= isMember ? "</a>" : "" %></td>
                    <td align="left" title="<%= label %>"><a href="<%= accountHref %>" target="_blank"><img src="../../images/<%= image %>" border="0" align="top" alt="o" />&nbsp;<%= (new ObjectReference(account, app)).getTitle() %></a></td>
                    <td align="left" title="<%= label %>">
                      <a href="<%= accountHref %>" target="_blank">
<%
                      for (
                        Iterator e = eMailAddresses.iterator();
                        e.hasNext();
                      ) {
                          String email = (String)e.next();
%>
                          <%= email %><br>
<%
                      }
%>
                      </a>
                    </td>
                    <td align="left" title="<%= label %>"><a href="<%= accountHref %>" target="_blank"><%= addressInfo %></a></td>
<%
                    if (isMember && !isDisabled) {
                      // is enabled member
%>
                      <td align="left" title="<%= app.getLabel(MEMBER_CLASS) %>">
                        <INPUT type="image" src="../../images/checked.gif" name="disable" tabindex="<%= tabIndex++ %>" value="&mdash;" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= member.refMofId() %>';" style="font-size:10px;font-weight:bold;" />&nbsp;&nbsp;
                        <INPUT type="image" src="../../images/delete.gif" name="delete" tabindex="<%= tabIndex++ %>" value="X" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= member.refMofId() %>';" style="font-size:10px;font-weight:bold;" title="<%= app.getTexts().getDeleteTitle() %>" />
                      </td>
                      <td align="left" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= memberRoles %></td>
                      <td align="center" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getValidFrom() != null ? timeFormat.format(member.getValidFrom()) : "--" %></td>
                      <td align="center" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getValidTo()   != null ? timeFormat.format(member.getValidTo())   : "--" %></td>
                      <td align="left" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getName() != null ? member.getName() : "" %></td>
                      <td align="left" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getDescription() != null ? member.getDescription() : "" %></td>
<%
                    } else if (isMember && isDisabled) {
                      // is disabled member
%>
                      <td align="left" title="<%= app.getLabel(MEMBER_CLASS) %> (<%= userView.getFieldLabel(MEMBER_CLASS, "disabled", app.getCurrentLocaleAsIndex()) %>)">
                        <INPUT type="image" src="../../images/ifneedbe.gif" name="enable" tabindex="<%= tabIndex++ %>" value="*" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= member.refMofId() %>';" style="font-size:10px;font-weight:bold;" /> (<%= userView.getFieldLabel(MEMBER_CLASS, "disabled", app.getCurrentLocaleAsIndex()) %>)&nbsp;&nbsp;
                        <INPUT type="image" src="../../images/delete.gif" name="delete" tabindex="<%= tabIndex++ %>" value="X" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= member.refMofId() %>';" style="font-size:10px;font-weight:bold;" title="<%= app.getTexts().getDeleteTitle() %>" />
                      </td>
                      <td align="left" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= memberRoles %></td>
                      <td align="center" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getValidFrom() != null ? timeFormat.format(member.getValidFrom()) : "--" %></td>
                      <td align="center" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getValidTo()   != null ? timeFormat.format(member.getValidTo())   : "--" %></td>
                      <td align="left" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getName() != null ? member.getName() : "" %></td>
                      <td align="left" <%= isMember ? "onclick='javascript:window.open(\"" + memberHref + "\");'" : "" %>><%= member.getDescription() != null ? member.getDescription() : "" %></td>
<%
                    } else {
                      // not a member
%>
                      <td align="left"><INPUT type="image" src="../../images/notchecked.gif" name="create" tabindex="<%= tabIndex++ %>" value="+" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= account.refMofId() %>';" style="font-size:10px;font-weight:bold;" /></td>
                      <td align="left"></td>
                      <td colspan="4">&nbsp;</td>
<%
                    }
%>
                  </tr>
<%
                  if (detectDuplicates && memberCounter > 1) {
                      //===================================================================
                      // deal with duplicates (members that reference to the same account)
                      //===================================================================
                      for(Iterator m = accountSource.getMember(isMemberFilter).iterator(); m.hasNext(); ) {
                          String currentMemberHref = "";
                          org.opencrx.kernel.account1.jmi1.Member currentMember = null;
                          try {
                              currentMember = (org.opencrx.kernel.account1.jmi1.Member)m.next();
                              action = new ObjectReference(
                                  currentMember,
                                  app
                              ).getSelectObjectAction();
                              currentMemberHref = "../../" + action.getEncodedHRef();
                          } catch (Exception e) {new ServiceException(e).log();}
                          boolean isEnabled = currentMember != null && (currentMember.isDisabled() == null || !currentMember.isDisabled().booleanValue());
                          if (currentMember.refMofId().compareTo(member.refMofId()) != 0) {
                            String currentMemberRoles = "";
                            for(
                                Iterator r = currentMember.getMemberRole().iterator();
                                r.hasNext();
                            ) {
                                currentMemberRoles += (String)(codes.getLongText("org:opencrx:kernel:account1:Member:memberRole", app.getCurrentLocaleAsIndex(), true, true).get(new Short((Short)r.next()))) + "<br />";
                            }
%>
                            <tr class="gridTableRowFull" style="<%= isEnabled ? "color:white;background-color:" + colorDuplicate + ";" : "font-style:italic;" %>"><!-- 6 columns -->
                              <td align="right" title="<%= app.getLabel(MEMBER_CLASS) %> referencing same <%= app.getLabel(ACCOUNT_CLASS) %>" onclick='javascript:window.open(\"" + currentMemberHref + "\");'><a href="<%= currentMemberHref %>" target="_blank"><img src="../../images/downRed3T.gif" border="0" align="top" alt="o" /></a></td>
                              <td align="left" title="<%= app.getLabel(MEMBER_CLASS) %> referencing same <%= app.getLabel(ACCOUNT_CLASS) %>"><a href="<%= currentMemberHref %>" target="_blank"><%= CAUTION %><img src="../../images/<%= image %>" border="0" align="top" alt="o" />&nbsp;<%= (new ObjectReference(account, app)).getTitle() %></a></td>
                              <td align="left" title="<%= app.getLabel(MEMBER_CLASS) %> referencing same <%= app.getLabel(ACCOUNT_CLASS) %>">&nbsp;</td>
                              <td align="left" title="<%= app.getLabel(MEMBER_CLASS) %> referencing same <%= app.getLabel(ACCOUNT_CLASS) %>">&nbsp;</td>
                              <td align="left" title="<%= app.getLabel(MEMBER_CLASS) %> referencing same <%= app.getLabel(ACCOUNT_CLASS) %>">
<%
                              if (isEnabled) {
%>
                                  <INPUT type="image" src="../../images/checked.gif" name="disable" tabindex="<%= tabIndex++ %>" value="&mdash;" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= currentMember.refMofId() %>';" style="font-size:10px;font-weight:bold;" />
<%
                              } else {
%>
                                  <INPUT type="image" src="../../images/ifneedbe.gif" name="enable" tabindex="<%= tabIndex++ %>" value="*" onmouseup="javascript:setTimeout('disableSubmit()', 10);this.style.display='none';this.name='ACTION.'+this.name;this.value='<%= currentMember.refMofId() %>';" style="font-size:10px;font-weight:bold;" />
                                  (<%= userView.getFieldLabel(MEMBER_CLASS, "disabled", app.getCurrentLocaleAsIndex()) %>)
<%
                              }
%>
                              </td>
                              <td align="left" onclick='javascript:window.open(\"" + currentMemberHref + "\");'><%= currentMemberRoles %></td>
                              <td align="center" onclick='javascript:window.open(\"" + currentMemberHref + "\");'><%= currentMember.getValidFrom() != null ? timeFormat.format(currentMember.getValidFrom()) : "--" %></td>
                              <td align="center" onclick='javascript:window.open(\"" + currentMemberHref + "\");'><%= currentMember.getValidTo()   != null ? timeFormat.format(currentMember.getValidTo())   : "--" %></td>
                              <td align="left" onclick='javascript:window.open(\"" + currentMemberHref + "\");'><%= currentMember.getName() != null ? currentMember.getName() : "" %></td>
                              <td align="left" onclick='javascript:window.open(\"" + currentMemberHref + "\");'><%= currentMember.getDescription() != null ? currentMember.getDescription() : "" %></td>
                            </tr>
<%
                          }
                      }
                  }

                  //===================================================================
                  // try to detect duplicates based on e-mail addresses
                  //===================================================================
                  //org.opencrx.kernel.account1.cci2.EMailAddressQuery eMailAddressFilter = accountPkg.createEMailAddressQuery();
                  //eMailAddressFilter.forAllDisabled().isFalse();
                  if (detectDuplicates) {
                      eMailAddressFilter.thereExistsEmailAddress().elementOf(new ArrayList(eMailAddresses));
                      for (
                        Iterator a = accountSegment.getAddress(eMailAddressFilter).iterator();
                        a.hasNext();
                      ) {
                          org.opencrx.kernel.account1.jmi1.EMailAddress addr = (org.opencrx.kernel.account1.jmi1.EMailAddress)a.next();
                          if (addr.getEmailAddress() != null && addr.getEmailAddress().length() > 0) {
                              // get parent account
                              org.opencrx.kernel.account1.jmi1.Account parentAccount = (org.opencrx.kernel.account1.jmi1.Account)pm.getObjectById(new Path(addr.refMofId()).getParent().getParent());
                              if (parentAccount.refMofId().compareTo(account.refMofId()) == 0) {
                                  continue; // found e-mail address of current account
                              }

                              String parentAccountHref = "";
                              action = new ObjectReference(
                                  parentAccount,
                                  app
                              ).getSelectObjectAction();
                              parentAccountHref = "../../" + action.getEncodedHRef();

                              image = "Contact.gif";
                              label = app.getLabel("org:opencrx:kernel:account1:Contact");
                              if (parentAccount instanceof org.opencrx.kernel.account1.jmi1.UnspecifiedAccount) {
                                image = "UnspecifiedAccount.gif";
                                label = app.getLabel("org:opencrx:kernel:account1:UnspecifiedAccount");
                              }
                              if (parentAccount instanceof org.opencrx.kernel.account1.jmi1.LegalEntity) {
                                image = "LegalEntity.gif";
                                label = app.getLabel("org:opencrx:kernel:account1:LegalEntity");
                              }
                              if (parentAccount instanceof org.opencrx.kernel.account1.jmi1.Group) {
                                image = "Group.gif";
                                label = app.getLabel("org:opencrx:kernel:account1:Group");
                              }
%>
                              <tr class="gridTableRowFull" style="color:white;background-color:<%= colorDuplicate %>;"><!-- 10 columns -->
                                <td align="right" title="<%= app.getLabel(ACCOUNT_CLASS) %> with duplicate <%= app.getLabel(EMAILADDRESS_CLASS) %>"><img src="../../images/downRed3T.gif" border="0" align="top" alt="o" /></td>
                                <td align="left" title="<%= app.getLabel(ACCOUNT_CLASS) %> with duplicate <%= app.getLabel(EMAILADDRESS_CLASS) %>"><a href="<%= parentAccountHref %>" target="_blank"><img src="../../images/<%= image %>" border="0" align="top" alt="o" />&nbsp;<%= (new ObjectReference(parentAccount, app)).getTitle() %></a></td>
                                <td align="left" title="<%= app.getLabel(ACCOUNT_CLASS) %> with duplicate <%= app.getLabel(EMAILADDRESS_CLASS) %>"><%= CAUTION %>
<%
                                    SortedSet<String> currentEMailAddresses = new TreeSet<String>();
                                    org.opencrx.kernel.account1.cci2.EMailAddressQuery ceMailAddressFilter = accountPkg.createEMailAddressQuery();
                                    ceMailAddressFilter.forAllDisabled().isFalse();
                                    for (
                                      Iterator ca = parentAccount.getAddress(eMailAddressFilter).iterator();
                                      ca.hasNext();
                                    ) {
                                        org.opencrx.kernel.account1.jmi1.EMailAddress caddr = (org.opencrx.kernel.account1.jmi1.EMailAddress)ca.next();
                                        if (caddr.getEmailAddress() != null && caddr.getEmailAddress().length() > 0) {
                                            // add this address to list
                                            currentEMailAddresses.add(caddr.getEmailAddress());
                                        }
                                    }
%>
                                    <a href="<%= parentAccountHref %>" target="_blank">
<%
                                        for (
                                          Iterator e = currentEMailAddresses.iterator();
                                          e.hasNext();
                                        ) {
                                            String email = (String)e.next();
%>
                                            <%= email %><br>
<%
                                        }
%>
                                    </a>
                                </td>
                                <td align="left" title="<%= app.getLabel(ACCOUNT_CLASS) %> with duplicate <%= app.getLabel(EMAILADDRESS_CLASS) %>">&nbsp;</td>
                                <td align="left" title="<%= app.getLabel(ACCOUNT_CLASS) %> with duplicate <%= app.getLabel(EMAILADDRESS_CLASS) %>">&nbsp;</td>
                                <td align="left" onclick='javascript:window.open(\"" + parentAccountHref + "\");'>&nbsp;</td>
                                <td align="left" onclick='javascript:window.open(\"" + parentAccountHref + "\");'>&nbsp;</td>
                                <td align="left" onclick='javascript:window.open(\"" + parentAccountHref + "\");'>&nbsp;</td>
                                <td align="left" onclick='javascript:window.open(\"" + parentAccountHref + "\");'>&nbsp;</td>
                                <td align="left" onclick='javascript:window.open(\"" + parentAccountHref + "\");'>&nbsp;</td>
                              </tr>
<%
                          }
                      }
                  }

              }
          }
%>
          <tr class="gridTableHeaderFull"><!-- 7 columns -->
            <td align="right">
              <a href="#" onclick="javascript:try{($('displayStart').value)--}catch(e){};$('Reload.Button').click();"><img border="0" align="top" alt="&lt;" src="../../images/previous.gif"></a>
              #
              <a href="#" onclick="javascript:try{($('displayStart').value)++}catch(e){};$('Reload.Button').click();"><img border="0" align="top" alt="&lt;" src="../../images/next.gif"></a></td>
            <td align="left">&nbsp;<b><%= app.getLabel(ACCOUNT_CLASS) %></b></td>
            <td align="left">&nbsp;<b><%= app.getLabel(EMAILADDRESS_CLASS) %></b></td>
            <td align="left">&nbsp;<b><%= app.getLabel(POSTALADDRESS_CLASS) %></b></td>
            <td align="left" nowrap><!-- <img src="../../images/NumberReplacement.gif" alt="" align="top" /> --><b><%= app.getLabel(MEMBERSHIP_CLASS) %></b></td>
            <td align="center">&nbsp;<b><%= userView.getFieldLabel(MEMBER_CLASS, "memberRole", app.getCurrentLocaleAsIndex()) %></b></td>
            <td align="center">&nbsp;<b><%= userView.getFieldLabel(MEMBER_CLASS, "validFrom", app.getCurrentLocaleAsIndex()) %></b></td>
            <td align="center">&nbsp;<b><%= userView.getFieldLabel(MEMBER_CLASS, "validTo", app.getCurrentLocaleAsIndex()) %></b></td>
            <td align="center"><b><%= userView.getFieldLabel(MEMBER_CLASS, "name", app.getCurrentLocaleAsIndex()) != null ? userView.getFieldLabel(MEMBER_CLASS, "name", app.getCurrentLocaleAsIndex()) : "" %></b></td>
            <td align="center"><b><%= userView.getFieldLabel(MEMBER_CLASS, "description", app.getCurrentLocaleAsIndex()) %></b></td>
          </tr>
        </table>
        </td></tr></table>
<%
        if (!highAccountIsKnown && (counter-1 > highAccount)) {
          highAccount = counter-1;
        }
%>
        <input type="hidden" name="highAccountIsKnown" id="highAccountIsKnown" value="<%= highAccountIsKnown ? "highAccountIsKnown" : ""  %>" />
        <input type="hidden" id="highAccount" name="highAccount" value="<%= highAccount %>" />
      </form>
<%
      String displayStartSelector = "<select onchange='javascript:$(\\\"waitMsg\\\").style.visibility=\\\"visible\\\";$(\\\"submitButtons\\\").style.visibility=\\\"hidden\\\";$(\\\"Reload.Button\\\").click();' id='displayStart' name='displayStart' tabindex='" + tabIndex++ + "' style='text-align:right;'>";
      int i = 0;
      while (i*pageSize < highAccount) {
        displayStartSelector += "<option " + (i == displayStart ? "selected" : "") + " value='" + formatter.format(i) + "'>" + formatter.format(pageSize*i + 1) + ".." + formatter.format(highAccount < pageSize*(i+1) ? highAccount : (pageSize*(i+1))) + "&nbsp;</option>";
        i++;
      }
      if (!highAccountIsKnown) {
        displayStartSelector += "<option value='" + formatter.format(i) + "'>" + formatter.format(pageSize*i + 1) + ".." + formatter.format(pageSize*(i+1)) + "&nbsp;</option>";
        displayStartSelector += "<option value='+100'>+100&nbsp;</option>";
        displayStartSelector += "<option value='+500'>+500&nbsp;</option>";
        displayStartSelector += "<option value='+1000'>+1000&nbsp;</option>";
        displayStartSelector += "<option value='+5000'>+5000&nbsp;</option>";
        displayStartSelector += "<option value='+10000'>+10000&nbsp;</option>";
        displayStartSelector += "<option value='+50000'>+50000&nbsp;</option>";
        displayStartSelector += "<option value='+100000'>+100000&nbsp;</option>";
        displayStartSelector += "<option value='+500000'>+500000&nbsp;</option>";
      }
      displayStartSelector += "</select>";
%>
      <script language='javascript' type='text/javascript'>
        try {
          $('displayStartSelector').innerHTML = "<%= displayStartSelector %>";
          $('highAccount').value = "<%= formatter.format(highAccount) %>";
          $('submitButtons').style.visibility='visible';
        } catch(e){};

        function disableSubmit() {
          $('waitMsg').style.display='block';
          $('submitButtons').style.display='none';
        }
      </script>
      <br />
      <INPUT type="Submit" name="Print.Button" tabindex="<%= tabIndex++ %>" value="Print" onClick="javascript:window.print();return false;" />
      <INPUT type="Submit" name="Cancel.Button" tabindex="<%= tabIndex++ %>" value="<%= app.getTexts().getCancelTitle() %>" onClick="javascript:window.close();" />
      <br />&nbsp;
<%
    }
    catch (Exception e) {
      out.println("<p><b>!! Failed !!<br><br>The following exception(s) occured:</b><br><br><pre>");
      PrintWriter pw = new PrintWriter(out);
      ServiceException e0 = new ServiceException(e);
      pw.println(e0.getMessage());
      pw.println(e0.getCause());
      out.println("</pre>");
    } finally {
    	if(pm != null) {
    		pm.close();
    	}
    }
%>
      </div> <!-- content -->
    </div> <!-- content-wrap -->
  </div> <!-- wrap -->
</div> <!-- container -->
</body>
</html>