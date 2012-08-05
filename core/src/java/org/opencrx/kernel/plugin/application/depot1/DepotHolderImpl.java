package org.opencrx.kernel.plugin.application.depot1;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.opencrx.kernel.backend.Backend;
import org.opencrx.kernel.depot1.jmi1.Depot;
import org.opencrx.kernel.depot1.jmi1.Depot1Package;
import org.openmdx.base.accessor.jmi.cci.JmiServiceException;
import org.openmdx.base.accessor.jmi.cci.RefPackage_1_3;
import org.openmdx.base.exception.ServiceException;
import org.openmdx.base.jmi1.BasePackage;

public class DepotHolderImpl {
    
    //-----------------------------------------------------------------------
    public DepotHolderImpl(
        org.opencrx.kernel.depot1.jmi1.DepotHolder current,
        org.opencrx.kernel.depot1.cci2.DepotHolder next
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
    public org.opencrx.kernel.depot1.jmi1.OpenDepotResult openDepot(
        org.opencrx.kernel.depot1.jmi1.OpenDepotParams params
    ) {
        try {
            List<String> errors = new ArrayList<String>();
            Depot depot = this.getBackend().getDepots().openDepot(
                this.current.refGetPath(),
                params.getName(),
                params.getDescription(),
                params.getDepotNumber(),
                params.getOpeningDate(),
                params.getDepotType() == null ? null : params.getDepotType().refGetPath(),
                params.getDepotGroup() == null ? null : params.getDepotGroup().refGetPath(),
                errors
            );
            if(depot == null) {
                return ((Depot1Package)this.current.refOutermostPackage().refPackage(Depot1Package.class.getName())).createOpenDepotResult(
                    null,
                    (short)1, 
                    errors.toString()
                );
            }
            else {
                return ((Depot1Package)this.current.refOutermostPackage().refPackage(Depot1Package.class.getName())).createOpenDepotResult(
                    depot,
                    (short)0, 
                    null
                );
            }
        }
        catch(ServiceException e) {
            throw new JmiServiceException(e);
        }
    }
    
    //-----------------------------------------------------------------------
    public org.openmdx.base.jmi1.Void assertReports(
        org.opencrx.kernel.depot1.jmi1.AssertReportsParams params
    ) {
        try {
            Collection<Depot> depots = this.current.getDepot();
            for(Depot depot: depots) {
                this.getBackend().getDepots().assertReports(
                    depot.refGetPath(),
                    params.getBookingStatusThreshold()
                );            
            }
            return ((BasePackage)this.current.refOutermostPackage().refPackage(BasePackage.class.getName())).createVoid();  
        }
        catch(ServiceException e) {
            throw new JmiServiceException(e);
        }                            
    }
    
    //-----------------------------------------------------------------------
    // Members
    //-----------------------------------------------------------------------
    protected final org.opencrx.kernel.depot1.jmi1.DepotHolder current;
    protected final org.opencrx.kernel.depot1.cci2.DepotHolder next;    
    
}