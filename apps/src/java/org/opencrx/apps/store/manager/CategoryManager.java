/*
 * ====================================================================
 * Project:     openCRX/Store, http://www.opencrx.org/
 * Name:        $Id: CategoryManager.java,v 1.6 2009/05/27 23:10:14 wfro Exp $
 * Description: CategoryManager
 * Revision:    $Revision: 1.6 $
 * Owner:       CRIXP AG, Switzerland, http://www.crixp.com
 * Date:        $Date: 2009/05/27 23:10:14 $
 * ====================================================================
 *
 * This software is published under the BSD license
 * as listed below.
 * 
 * Copyright (c) 2007, CRIXP Corp., Switzerland
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
package org.opencrx.apps.store.manager;

import java.util.Collection;
import java.util.List;

import javax.jdo.Transaction;

import org.opencrx.apps.store.common.ObjectCollection;
import org.opencrx.apps.store.common.PrimaryKey;
import org.opencrx.apps.store.common.util.Keys;
import org.opencrx.apps.store.objects.Category;
import org.opencrx.apps.utils.ApplicationContext;
import org.opencrx.kernel.product1.cci2.ProductClassificationQuery;
import org.opencrx.kernel.product1.cci2.ProductClassificationRelationshipQuery;
import org.opencrx.kernel.product1.jmi1.ProductClassification;
import org.opencrx.kernel.product1.jmi1.ProductClassificationRelationship;
import org.openmdx.base.exception.ServiceException;
import org.openmdx.kernel.id.UUIDs;
import org.openmdx.kernel.id.cci.UUIDGenerator;

/**
 * Manager for Category subsystem
 * 
 * @author OAZM (initial implementation)
 * @author WFRO (port to openCRX)
 */
public final class CategoryManager
{
    public CategoryManager(
        ApplicationContext context
    ) {
        this.context = context;
    }
    
    //-----------------------------------------------------------------------
    public final boolean create(
        final Category newValue
    ) {
    	Transaction tx = null;
        try {
            UUIDGenerator uuids = UUIDs.getGenerator();
            tx = this.context.getPersistenceManager().currentTransaction();       
            tx.begin();
            org.opencrx.kernel.product1.jmi1.ProductClassification classification = 
                this.context.getPersistenceManager().newInstance(org.opencrx.kernel.product1.jmi1.ProductClassification.class);
            classification.refInitialize(false, true);
            newValue.update(
                classification, 
                this.context
            );
            classification.setName(
                Keys.STORE_SCHEMA + newValue.getTitle()
            );
            this.context.getProductSegment().addProductClassification(
                false,
                newValue.getKey().getUuid(),
                classification
            );
            tx.commit();
            // Get parent classification
            ProductClassification parent = null;            
            if(
                (newValue.getParentID() != null) &&
                (newValue.getParentID().getUuid().length() > 0)
            ) {
                parent = 
                    context.getProductSegment().getProductClassification(newValue.getParentID().getUuid());
            }
            // OpenCrxContext.SCHEMA_STORE + CATEGORY_NAME_PRODUCTS as default root classification 
            else {
                ProductClassificationQuery query = (ProductClassificationQuery)this.context.getPersistenceManager().newQuery(ProductClassification.class);                
                query.name().equalTo(Keys.STORE_SCHEMA + Category.CATEGORY_NAME_PRODUCTS);
                Collection<ProductClassification> classifications = this.context.getProductSegment().getProductClassification(query);
                if(!classifications.isEmpty()) {
                    parent = classifications.iterator().next();
                }
                // Create root classification on demand
                else {
                    tx.begin();
                    parent = this.context.getPersistenceManager().newInstance(ProductClassification.class);
                    parent.refInitialize(false, true);
                    parent.setName(Keys.STORE_SCHEMA + Category.CATEGORY_NAME_PRODUCTS);
                    parent.setDescription(Category.CATEGORY_NAME_PRODUCTS);
                    this.context.getProductSegment().addProductClassification(
                        false,
                        uuids.next().toString(),
                        parent
                    );
                    tx.commit();
                }
            }
            // Add relationship to parent
            tx.begin();
            ProductClassificationRelationship relationship = this.context.getPersistenceManager().newInstance(ProductClassificationRelationship.class);
            relationship.refInitialize(false, true);
            relationship.setName(parent.getName());
            relationship.setRelationshipType((short)0);
            relationship.setRelationshipTo(parent);
            classification.addRelationship(
                false,
                uuids.next().toString(),
                relationship
            );
            tx.commit();
            return true;
        }
        catch(Exception e) {
        	if(tx != null) {
        		try {
        			tx.rollback();
        		}
        		catch(Exception e0) {}
        	}
            new ServiceException(e).log();
            return false;
        }        
    }

    //-----------------------------------------------------------------------
    public final void delete(
        final PrimaryKey key
    ) {
    	Transaction tx = null;
    	try {
	        tx = this.context.getPersistenceManager().currentTransaction();       
	        tx.begin();
	        org.opencrx.kernel.product1.jmi1.ProductClassification classification = 
	            this.context.getProductSegment().getProductClassification(key.getUuid());
	        classification.refDelete();
	        tx.commit();
    	}
        catch(Exception e) {
        	if(tx != null) {
        		try {
        			tx.rollback();
        		}
        		catch(Exception e0) {}
        	}
            new ServiceException(e).log();
        }            	
    }

    //-----------------------------------------------------------------------
    public final Category get(
        final PrimaryKey key
    ) {
        if(key.toString().length() > 0) {
            org.opencrx.kernel.product1.jmi1.ProductClassification classification = 
                this.context.getProductSegment().getProductClassification(key.getUuid());
            return new Category(classification);
        }
        else {
            return null;
        }
    }

    //-----------------------------------------------------------------------
    public final ObjectCollection getChildren(
        final PrimaryKey categoryID
    ) {
        ObjectCollection children = new ObjectCollection();
        org.opencrx.kernel.product1.jmi1.ProductClassification parent = null;
        if(categoryID.toString().length() == 0) {
            ProductClassificationQuery query = (ProductClassificationQuery)this.context.getPersistenceManager().newQuery(org.opencrx.kernel.product1.jmi1.ProductClassification.class);
            query.name().equalTo(Keys.STORE_SCHEMA + Category.CATEGORY_NAME_PRODUCTS);
            Collection<ProductClassification> classifications = this.context.getProductSegment().getProductClassification(query);
            if(!classifications.isEmpty()) {
                parent = classifications.iterator().next();
            }
        }
        else {
            parent = this.context.getProductSegment().getProductClassification(categoryID.getUuid());
        }
        if(parent != null) {
            ProductClassificationRelationshipQuery query = (ProductClassificationRelationshipQuery)this.context.getPersistenceManager().newQuery(ProductClassificationRelationship.class);
            query.thereExistsRelationshipTo().equalTo(parent);
            query.identity().like(
            	this.context.getProductSegment().refGetPath().getDescendant("productClassification", ":*", "relationship", ":*").toXRI()
            );
            List<ProductClassificationRelationship> relationships = this.context.getProductSegment().getExtent(query);
            for(ProductClassificationRelationship relationship: relationships) {
                ProductClassification classification = relationship.getClassification();
                Category category = new Category(classification);
                children.put(
                    category.getKey().toString(), 
                    category
                );
            }
        }
        return children;
    }

    //-----------------------------------------------------------------------
    public final Category update(
        final Category newValue
    ) {
    	Transaction tx = null;
    	try {
	        tx = this.context.getPersistenceManager().currentTransaction();       
	        tx.begin();
	        org.opencrx.kernel.product1.jmi1.ProductClassification classification = 
	            this.context.getProductSegment().getProductClassification(newValue.getKey().getUuid());
	        newValue.update(
	            classification,
	            this.context
	        );
	        tx.commit();
	        return this.get(newValue.getKey());
    	}
        catch(Exception e) {
        	if(tx != null) {
        		try {
        			tx.rollback();
        		}
        		catch(Exception e0) {}
        	}
            new ServiceException(e).log();
            return null;
        }            	
    }

    //-----------------------------------------------------------------------
    // Members
    //-----------------------------------------------------------------------
    private final ApplicationContext context;
        
}