/*
 * ====================================================================
 * Project:     openCRX/Core, http://www.opencrx.org/
 * Name:        $Id: CopyDb.java,v 1.33 2008/10/06 17:04:53 wfro Exp $
 * Description: CopyDb tool
 * Revision:    $Revision: 1.33 $
 * Owner:       CRIXP AG, Switzerland, http://www.crixp.com
 * Date:        $Date: 2008/10/06 17:04:53 $
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
package org.opencrx.kernel.tools;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.Reader;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Properties;
import java.util.Set;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import org.openmdx.base.exception.ServiceException;
import org.openmdx.compatibility.base.application.configuration.Configuration;
import org.openmdx.compatibility.base.dataprovider.layer.persistence.jdbc.Database_1Jdbc2;
import org.openmdx.compatibility.base.dataprovider.layer.persistence.jdbc.LayerConfigurationEntries;
import org.openmdx.kernel.exception.BasicException;
import org.openmdx.model1.accessor.basic.spi.Model_1;

public class CopyDb {

    //---------------------------------------------------------------------------
    private static String getStringFromClob(
        java.sql.Clob clob
    ) throws IOException, SQLException {
        Reader reader = clob.getCharacterStream();
        StringBuilder s = new StringBuilder();
        int c;
        while((c = reader.read()) != -1) {
            s.append((char)c);
        }
        return s.toString();        
    }
    
    //---------------------------------------------------------------------------
    private static byte[] getBytesFromBlob(
        java.sql.Blob blob
    ) throws IOException, SQLException {
        InputStream is = blob.getBinaryStream();
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        int b;
        while((b = is.read()) != -1) {
            os.write(b);
        }
        os.close();
        return os.toByteArray();   
    }
    
    //---------------------------------------------------------------------------
    private static String mapColumnName(
        Connection conn,
        String dbObject,
        String columnName
    ) throws SQLException {
        String databaseProductName = conn.getMetaData().getDatabaseProductName();
        if("HSQL Database Engine".equals(databaseProductName)) {
            String mappedColumnName = columnName.toUpperCase();
            if("POSITION".equals(mappedColumnName)) {
                return "\"" + mappedColumnName + "\"";
            }
            else {
                return mappedColumnName;
            }
        }
        else {
            return columnName.toUpperCase();
        }
    }
    
    //---------------------------------------------------------------------------
    private static Object mapColumnValue(
        Connection conn,
        String dbObject,
        String columnName,
        Object columnValue
    ) throws ServiceException, SQLException {
        String databaseProductName = conn.getMetaData().getDatabaseProductName();        
        if(BOOLEAN_COLUMNS.contains(columnName.toUpperCase())) {
            if("PostgreSQL".equals(databaseProductName)) {
                return columnValue;
            }
            else if("MySQL".equals(databaseProductName)) {
                return columnValue;
            }
            else if("Microsoft SQL Server".equals(databaseProductName)) {
                return columnValue;
            }
            else if(databaseProductName.startsWith("DB2/")) {
                return Boolean.valueOf("Y".equals(columnValue));
            }
            else if("HSQL Database Engine".equals(databaseProductName)) {
                return columnValue;                
            }
            else if("Oracle".equals(databaseProductName)) {      
                return Boolean.valueOf(((Number)columnValue).intValue() == 1);
            }
            else {
                throw new ServiceException(
                    BasicException.Code.DEFAULT_DOMAIN,
                    BasicException.Code.NOT_SUPPORTED, 
                    new BasicException.Parameter[]{
                      new BasicException.Parameter("database product name", databaseProductName)
                    },
                    "Database not supported"
                );
            }
        }
        else {
            return columnValue;
        }
    }
    
    //---------------------------------------------------------------------------
    private static void copyDbObject(
        String[] namespaceSource,
        String[] namespaceTarget,
        String dbObject,
        boolean useSuffix,
        Connection connSource,
        Connection connTarget
    ) throws SQLException {

        String currentStatement = null;
                    
        Database_1Jdbc2 db = new Database_1Jdbc2();
        try {
            Configuration configuration = new Configuration();
            configuration.values(LayerConfigurationEntries.BOOLEAN_TYPE).add(LayerConfigurationEntries.BOOLEAN_TYPE_STANDARD);
            configuration.values(LayerConfigurationEntries.XML_DATATYPES).add(Boolean.TRUE);
            configuration.values(LayerConfigurationEntries.MODEL).add(new Model_1());
            configuration.values(LayerConfigurationEntries.DATABASE_CONNECTION_FACTORY );           
            db.activate(
                (short)0,
                configuration,
                null
            );
        } catch(Exception e) {
            System.out.println("Can not activate database plugin: " + e.getMessage());
        }
        try {
            // Delete all rows from target                    
            PreparedStatement s = connTarget.prepareStatement(
                currentStatement = "DELETE FROM " + namespaceTarget[0] + "_" + dbObject + (useSuffix ? namespaceTarget[1] : "")
            );
            s.executeUpdate();
            s.close();
            
            // Read all rows from source
            s = connSource.prepareStatement(
                currentStatement = "SELECT * FROM " + namespaceSource[0] + "_" + dbObject + (useSuffix ? namespaceSource[1] : "")
            );
            s.executeQuery();
            ResultSet rs = s.getResultSet(); 
            ResultSetMetaData rsm = rs.getMetaData();
            FastResultSet frs = new FastResultSet(rs);
            int nRows = 0;
            
            while(frs.next()) {
                // Read row from source and prepare INSERT statement
                String statement = "INSERT INTO " + namespaceTarget[0] + "_" + dbObject + (useSuffix ? namespaceTarget[1] : "") + " ";
                List<Object> statementParameters = new ArrayList<Object>();
                List<String> processTargetColumnNames = new ArrayList<String>();
                for(
                    int j =  0;
                    j < rsm.getColumnCount();
                    j++
                ) {
                    String columnName = rsm.getColumnName(j+1);                    
                    if(frs.getObject(columnName) != null) {
                        String mappedColumnName = mapColumnName(
                            connTarget,
                            dbObject, 
                            columnName 
                        );
                        if(mappedColumnName != null) {
                            statement += (statementParameters.size() == 0 ? " (" : ", ") + mappedColumnName;
                            processTargetColumnNames.add(mappedColumnName);
                            if(frs.getObject(columnName) instanceof java.sql.Clob) {
                                try {
                                    statementParameters.add(
                                        getStringFromClob((java.sql.Clob)frs.getObject(columnName))
                                    );
                                }
                                catch(Exception e) {
                                    System.out.println("Reading Clob failed. Reason: " + e.getMessage());
                                    System.out.println("statement=" + statement);
                                    System.out.println("parameters=" + statementParameters);
                                }
                            }
                            else if(frs.getObject(columnName) instanceof java.sql.Blob) {
                                try {
                                    statementParameters.add(
                                        getBytesFromBlob((java.sql.Blob)frs.getObject(columnName))
                                    );
                                }
                                catch(Exception e) {
                                    System.out.println("Reading Blob failed. Reason: " + e.getMessage());
                                    System.out.println("statement=" + statement);
                                    System.out.println("parameters=" + statementParameters);
                                }
                            }
                            else {
                                statementParameters.add(
                                    mapColumnValue(
                                        connSource,
                                        dbObject,
                                        columnName,
                                        frs.getObject(columnName)
                                    )
                                );
                            }
                        }
                    }
                }
                statement += ") VALUES (";
                for(int j = 0; j < statementParameters.size(); j++) {
                    statement += j == 0 ? "?" : ", ?";
                }
                statement += ")";
                
                // Add row to target
                try {
                    PreparedStatement t = connTarget.prepareStatement(
                        currentStatement = statement
                    );
                    for(int j = 0; j < statementParameters.size(); j++) {
                        Object parameter = statementParameters.get(j);                        
                        if("oracle.sql.TIMESTAMP".equals(parameter.getClass().getName())) {
                            Method timestampValueMethod = parameter.getClass().getMethod("timestampValue", new Class[]{});
                            parameter = timestampValueMethod.invoke(
                                parameter, 
                                new Object[]{}
                            );
                        }
                        if(parameter instanceof java.sql.Timestamp) {
                            t.setTimestamp(
                                j+1, 
                                (java.sql.Timestamp)parameter
                            );
                        }
                        else if(parameter instanceof java.sql.Date) {
                            t.setDate(
                                j+1, 
                                (java.sql.Date)parameter
                            );
                        }
                        else {
                            db.setPreparedStatementValue(
                                connTarget,
                                t,
                                j+1,
                                parameter
                            );
                        }
                    }
                    t.executeUpdate();
                    t.close();                  
                }
                catch(Exception e) {
                    new ServiceException(e).log();
                    System.out.println("Insert failed. Reason: " + e.getMessage());
                    System.out.println("statement=" + statement);
                    System.out.println("parameters=" + statementParameters);
                }
                nRows++;
                if(nRows % 1000 == 0) {
                    System.out.println(nRows + " rows copied");
                }
            }
            rs.close();
            s.close();
        }
        catch(Exception e) {
            new ServiceException(e).log();
            System.out.println("Can not copy table (see log for more info). Statement: " + currentStatement);
        }
    }
    
    //---------------------------------------------------------------------------
    private static void copyNamespace(
        Connection connSource,
        Connection connTarget,
        String[] namespaceSource,
        String[] namespaceTarget,
        List<String> dbObjects,
        int startFromDbObject,
        int endWithDbObject
    ) {
        String currentStatement = null;           
        try {
            System.out.println();
            System.out.println("Copying namespace from source=" + namespaceSource[0] + " to target=" + namespaceTarget[0]);
            
            System.out.println();
            System.out.println("Processing tables");
            System.out.println(dbObjects);
            
            Set<String> processedDbObjects = new HashSet<String>();
            for(                  
                int i = 0;
                (i < dbObjects.size()) && (i <= endWithDbObject);
                i++
            ) {
                String dbObject = dbObjects.get(i);
                if((dbObject != null) && (dbObject.length() > 0) && !processedDbObjects.contains(dbObject)) {
                    if(i >= startFromDbObject) {
                        System.out.println("Copying table " + i + " (" + dbObject + ")");
                        copyDbObject(
                            namespaceSource,
                            namespaceTarget,
                            dbObject,
                            false,
                            connSource,
                            connTarget
                        );
                        copyDbObject(
                            namespaceSource,
                            namespaceTarget,
                            dbObject,
                            true,
                            connSource,
                            connTarget
                        );
                    }
                    else {
                        System.out.println("Skipping table " + i + " (" + dbObject + ")");                        
                    }
                    processedDbObjects.add(dbObject);
                }
            }                                    
            System.out.println("INFO: Done");
        }
        catch (SQLException e) {
            e.printStackTrace();
            System.out.println("statement: " + currentStatement);
        }
    }

   //-----------------------------------------------------------------------
    public static void main(
        String[] args
    ) {
        try {
            Context componentEnvironment = (Context)new InitialContext().lookup("java:comp/env");

            // Source connection
            Class.forName((String)componentEnvironment.lookup("jdbcDriverSource"));
            Properties props = new Properties();
            props.put("user", componentEnvironment.lookup("usernameSource"));
            props.put("password", componentEnvironment.lookup("passwordSource"));
            Connection connSource = DriverManager.getConnection(
                (String)componentEnvironment.lookup("jdbcUrlSource"),
                props
            );
            connSource.setAutoCommit(true);

            // Target connection
            Class.forName((String)componentEnvironment.lookup("jdbcDriverTarget"));
            props = new Properties();
            props.put("user", componentEnvironment.lookup("usernameTarget"));
            props.put("password", componentEnvironment.lookup("passwordTarget"));
            Connection connTarget = DriverManager.getConnection(
                (String)componentEnvironment.lookup("jdbcUrlTarget"),
                props
            );
            connTarget.setAutoCommit(true);
                        
            Number kernelStartFromDbObject = (Number)componentEnvironment.lookup("kernel.startFromDbObject");
            Number securityStartFromDbObject = (Number)componentEnvironment.lookup("security.startFromDbObject");
            String formatSource = (String)componentEnvironment.lookup("formatSource");
            String formatTarget = (String)componentEnvironment.lookup("formatTarget");
            if(
                formatSource.equals(formatTarget) &&
                (kernelStartFromDbObject != null) &&
                (kernelStartFromDbObject.intValue() == 0) &&
                (securityStartFromDbObject != null) &&
                (securityStartFromDbObject.intValue() == 0)
            ) {               
                copyDbObject(
                    new String[]{"prefs", ""},
                    new String[]{"prefs", ""},
                    "Preference",
                    false,
                    connSource,
                    connTarget
                );
            }
            // Namespace kernel
            Number endWithDbObject = (Number)componentEnvironment.lookup("kernel.endWithDbObject");
            copyNamespace(
                connSource,
                connTarget,
                new String[]{"OOCKE1", "_"},
                new String[]{"OOCKE1", "_"},
                Arrays.asList(DBOBJECTS_KERNEL),
                kernelStartFromDbObject == null ? 0 : kernelStartFromDbObject.intValue(),
                endWithDbObject == null ? Integer.MAX_VALUE : endWithDbObject.intValue()
            );
            // Namespace security
            endWithDbObject = (Number)componentEnvironment.lookup("security.endWithDbObject");
            copyNamespace(
                connSource,
                connTarget,
                new String[]{"OOCSE1", "_"},
                new String[]{"OOCSE1", "_"},
                Arrays.asList(DBOBJECTS_SECURITY),
                securityStartFromDbObject == null ? 0 : securityStartFromDbObject.intValue(),
                endWithDbObject == null ? Integer.MAX_VALUE : endWithDbObject.intValue()
            );            
        }
        catch(NamingException e) {
            e.printStackTrace();
        }
        catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    //-----------------------------------------------------------------------
    // Members
    //-----------------------------------------------------------------------
    static final String[] DBOBJECTS_KERNEL = new String[]{
        "ACCESSHISTORY",
        "ACCOUNT",
        "ACCOUNTASSIGNMENT",
        "ACTIVITY",
        "ACTIVITYCREATOR",
        "ACTIVITYEFFORTESTI",
        "ACTIVITYFOLLOWUP",
        "ACTIVITYGROUP",
        "ACTIVITYGROUPASS",
        "ACTIVITYLINK",
        "ACTIVITYPARTY",
        "ACTIVITYPROCACTION",
        "ACTIVITYPROCESS",
        "ACTIVITYPROCSTATE",
        "ACTIVITYPROCTRANS",
        "ACTIVITYTYPE",
        "ADDITIONALEXTLINK",
        "ADDRESS",
        "ADDRESSGROUP",
        "ADDRESSGROUPMEMBER",
        "ALERT",
        "AUDITENTRY",
        "BOOKING",
        "BOOKINGPERIOD",
        "BOOKINGTEXT",
        "BUDGET",
        "BUILDINGUNIT",
        "CALCULATIONRULE",
        "CALENDAR",
        "CALENDARDAY",
        "CALENDARFEED",
        "CALENDARPROFILE",
        "CHART",
        "CODEVALUECONTAINER",
        "CODEVALUEENTRY",
        "COMPETITOR",
        "COMPONENTCONFIG",
        "COMPOUNDBOOKING",
        "CONTACTMEMBERSHIP",
        "CONTACTREL",
        "CONTACTROLE",
        "CONTRACT",
        "CONTRACTLINK",
        "CONTRACTPOSITION",
        "CONTRACTPOSMOD",
        "CREDITLIMIT",
        "DELIVERYINFO",
        "DELIVERYREQUEST",
        "DEPOT",
        "DEPOTENTITY",
        "DEPOTENTITYREL",
        "DEPOTGROUP",
        "DEPOTHOLDER",
        "DEPOTPOSITION",
        "DEPOTREFERENCE",
        "DEPOTREPORT",
        "DEPOTREPORTITEM",
        "DEPOTTYPE",
        "DESCRIPTION",
        "DOCUMENT",
        "DOCUMENTATTACHMENT",
        "DOCUMENTFOLDER",
        "DOCUMENTFOLDERASS",        
        "DOCUMENTLINK",
        "DOCUMENTLOCK",
        "EMAILACCOUNT",
        "EVENT",
        "EVENTPART",
        "EVENTSLOT",
        "EXPORTPROFILE",
        "FACILITY",
        "FILTER",
        "FILTERPROPERTY",
        "INDEXENTRY",
        "INVENTORYITEM",
        "INVOLVEDOBJECT",
        "LINKABLEITEMLINK",
        "MEDIA",
        "MODELELEMENT",
        "NOTE",
        "OBJECTFINDER",
        "ORGANIZATION",
        "ORGANIZATIONALUNIT",
        "ORGUNITRELSHIP",
        "PRICELEVEL",
        "PRICEMODIFIER",
        "PRICINGRULE",
        "PRODUCT",
        "PRODUCTAPPLICATION",
        "PRODUCTBASEPRICE",
        "PRODUCTCLASS",
        "PRODUCTCLASSREL",
        "PRODUCTCONFIG",
        "PRODUCTCONFTYPESET",
        "PRODUCTPHASE",
        "PRODUCTREFERENCE",
        "PROPERTY",
        "PROPERTYSET",
        "QUICKACCESS",
        "RASARTIFACTCONTEXT",
        "RASARTIFACTDEP",
        "RASCLASSIFICATIELT",
        "RASDESCRIPTOR",
        "RASPROFILE",
        "RASSOLUTIONPART",
        "RASVARPOINT",
        "RATING",
        "RELATEDPRODUCT",
        "RESOURCE",
        "RESOURCEASSIGNMENT",
        "REVENUEREPORT",
        "SALESTAXTYPE",
        "SEGMENT",
        "SIMPLEBOOKING",
        "SUBSCRIPTION",
        "TOPIC",
        "UOM",
        "UOMSCHEDULE",
        "USERHOME",
        "VOTE",
        "WFACTIONLOGENTRY",
        "WFPROCESS",
        "WFPROCESSINSTANCE",
        "WORKRECORD"    
    };
    
    static final String[] DBOBJECTS_SECURITY = new String[]{
        "AUTHENTICATIONCONTEXT",
        "CREDENTIAL",
        "PERMISSION",
        "POLICY",
        "PRINCIPAL",
        "PRIVILEGE",
        "REALM",
        "ROLE",
        "SEGMENT",
        "SUBJECT"        
    };
        
    static final Set<String> BOOLEAN_COLUMNS = new HashSet<String>(
        Arrays.asList(
            new String[]{
                "DISABLED",
                "USER_BOOLEAN0",
                "USER_BOOLEAN1",
                "USER_BOOLEAN2",
                "USER_BOOLEAN3",
                "USER_BOOLEAN4",
                "DO_NOT_BULK_POSTAL_MAIL",
                "DO_NOT_E_MAIL",
                "DO_NOT_FAX",
                "DO_NOT_PHONE",
                "DO_NOT_POSTAL_MAIL",
                "EXT_BOOLEAN0",
                "EXT_BOOLEAN1",
                "EXT_BOOLEAN2",
                "EXT_BOOLEAN3",
                "EXT_BOOLEAN4",
                "EXT_BOOLEAN5",
                "EXT_BOOLEAN6",
                "EXT_BOOLEAN7",
                "EXT_BOOLEAN8",
                "EXT_BOOLEAN9",
                "USER_BOOLEAN4",
                "DISABLED",
                "DISCOUNT_IS_PERCENTAGE",
                "USER_BOOLEAN4",
                "IS_ALL_DAY_EVENT",
                "DELIVERY_RECEIPT_REQUESTED",
                "READ_RECEIPT_REQUESTED",
                "IS_MAIN",
                "RESET_TO_NULL",
                "IS_MAIN",
                "AUTOMATIC_PARSING",
                "IS_CLOSED",
                "IS_FINAL",
                "CREDIT_FIRST",
                "IS_DEFAULT",
                "IS_WORKING_DAY",
                "IS_LOCKED",
                "IS_GIFT",
                "IS_TEMPLATE",
                "DISCOUNT_IS_PERCENTAGE",
                "IS_GIFT",
                "SALES_COMMISSION_IS_PERCENTAGE",
                "IS_CREDIT_ON_HOLD",
                "ALLOW_POSITION_AUTO_CREATE",
                "IS_DEFAULT",
                "IS_LOCKED",
                "IS_TEMPLATE",
                "IS_LOCKED",
                "HOLDER_QUALIFIES_POSITION",
                "IS_DRAFT",
                "ALLOW_CREDIT_BOOKINGS",
                "ALLOW_DEBIT_BOOKINGS",
                "IS_DEFAULT",
                "IS_ACTIVE",
                "IS_MAIN",
                "BOOLEAN_PARAM",
                "IS_CHANGEABLE",
                "IS_QUERY",
                "IS_DERIVED",
                "IS_ABSTRACT",
                "IS_SINGLETON",
                "IS_CLUSTERED",
                "IS_NAVIGABLE",
                "WEIGHT_IS_PERCENTAGE",
                "IS_FINAL",
                "DISCOUNT_IS_PERCENTAGE",
                "IS_DEFAULT",
                "ALLOW_MODIFICATION",
                "ALLOW_REMOVAL",
                "DISCOUNT_IS_PERCENTAGE",
                "OVERRIDE_PRICE",
                "IS_STOCK_ITEM",
                "DISCOUNT_IS_PERCENTAGE",
                "IS_DEFAULT",
                "BOOLEAN_VALUE",
                "IS_ACTIVE",
                "NEW_BOOLEAN",
                "OLD_BOOLEAN",
                "SELECTOR",
                "IS_SCHEDULE_BASE_UOM",
                "STORE_SETTINGS_ON_LOGOFF",
                "IS_SYNCHRONOUS",
                "FAILED",
                "IS_BILLABLE",
                "LOCKED"
            }
        )
    );
    
}

//---------------------------------------------------------------------------