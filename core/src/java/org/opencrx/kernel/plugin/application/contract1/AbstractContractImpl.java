/*
 * ====================================================================
 * Project:     openCRX/Core, http://www.opencrx.org/
 * Name:        $Id: AbstractContractImpl.java,v 1.7 2008/07/08 23:11:54 wfro Exp $
 * Description: openCRX application plugin
 * Revision:    $Revision: 1.7 $
 * Owner:       CRIXP AG, Switzerland, http://www.crixp.com
 * Date:        $Date: 2008/07/08 23:11:54 $
 * ====================================================================
 *
 * This software is published under the BSD license
 * as listed below.
 * 
 * Copyright (c) 2004-2007, CRIXP Corp., Switzerland
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
package org.opencrx.kernel.plugin.application.contract1;

import org.opencrx.kernel.backend.Backend;
import org.opencrx.kernel.contract1.jmi1.Contract1Package;
import org.opencrx.kernel.contract1.jmi1.ContractPosition;
import org.opencrx.kernel.depot1.jmi1.CompoundBooking;
import org.openmdx.base.accessor.jmi.cci.JmiServiceException;
import org.openmdx.base.accessor.jmi.cci.RefPackage_1_3;
import org.openmdx.base.exception.ServiceException;
import org.openmdx.base.jmi1.BasePackage;

public class AbstractContractImpl {

    //-----------------------------------------------------------------------
    public AbstractContractImpl(
        org.opencrx.kernel.contract1.jmi1.AbstractContract current,
        org.opencrx.kernel.contract1.cci2.AbstractContract next
    ) {
        this.current = current;
        this.next = next;
    }

    //-----------------------------------------------------------------------
    public Backend getBackend(
    ) {
        return (Backend)((RefPackage_1_3)this.current.refOutermostPackage()).refUserContext();
    }
    
    //-----------------------------------------------------------------------
    public org.opencrx.kernel.contract1.jmi1.UpdateInventoryResult updateInventory(
    ) {
        try {
            CompoundBooking compoundBooking = this.getBackend().getContracts().updateInventory(
                this.current.refGetPath()
            );
            return ((Contract1Package)this.current.refOutermostPackage().refPackage(Contract1Package.class.getName())).createUpdateInventoryResult(
                compoundBooking
            );
        }
        catch(ServiceException e) {
            throw new JmiServiceException(e);
        }        
    }
    
    //-----------------------------------------------------------------------
    public org.openmdx.base.jmi1.Void removePendingInventoryBookings(
    ) {
        try {
            this.getBackend().getContracts().removePendingInventoryBookings(
                this.current.refGetPath()
            );
            return ((BasePackage)this.current.refOutermostPackage().refPackage(BasePackage.class.getName())).createVoid();
        }
        catch(ServiceException e) {
            throw new JmiServiceException(e);
        }        
    }
    
    //-----------------------------------------------------------------------
    public org.openmdx.base.jmi1.Void reprice(
    ) {
        try {
            this.getBackend().getContracts().repriceContract(
                this.current.refGetPath()
            );
            return ((BasePackage)this.current.refOutermostPackage().refPackage(BasePackage.class.getName())).createVoid();
        }
        catch(ServiceException e) {
            throw new JmiServiceException(e);
        }                
    }
    
    //-----------------------------------------------------------------------
    public org.opencrx.kernel.contract1.jmi1.CreatePositionResult createPosition(
        org.opencrx.kernel.contract1.jmi1.CreatePositionParams params
    ) {
        ContractPosition position = this.getBackend().getContracts().createContractPosition(
            this.current.refGetPath(),
            params.getName(),
            params.getQuantity(),
            params.getPricingDate(),
            params.getProduct() == null ? null : params.getProduct().refGetPath(),
            params.getUom() == null ? null : params.getUom().refGetPath(),
            params.getPriceUom() == null ? null : params.getPriceUom().refGetPath(),
            params.getPricingRule() == null ? null : params.getPricingRule().refGetPath(),
            false
        );
        return ((Contract1Package)this.current.refOutermostPackage().refPackage(Contract1Package.class.getName())).createCreatePositionResult(
            position
        );
    }

    //-----------------------------------------------------------------------
    // Members
    //-----------------------------------------------------------------------
    protected final org.opencrx.kernel.contract1.jmi1.AbstractContract current;
    protected final org.opencrx.kernel.contract1.cci2.AbstractContract next;    
    
}