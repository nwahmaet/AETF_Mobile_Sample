/** ****************************************************************************
  Copyright 2013 Progress Software Corporation
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
    http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
**************************************************************************** **/
 /*------------------------------------------------------------------------
    File        : DealerService
    Syntax      : 
    Author(s)   : pjudge
    Created     : Thu Jan 10 13:23:00 EST 2013
    Notes       : 
  ----------------------------------------------------------------------*/
@program FILE(name="DealerService.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="DealerService", URI="/Dealer", schemaName="dsDealer", schemaFile="AETF Mobile Sample/src/AppServer/DealerService.cls").

routine-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.Error.
using Progress.Lang.AppError.

class DealerService inherits BusinessEntity:
    {dsDealer.i}
    
    constructor public DealerService (  ):
        super ().
    end constructor.

    /*------------------------------------------------------------------------------
            Purpose:  Get one or more records, based on a filter string                                                                     
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json"). 
    method public void ReadDealerService(input filter as character,  /* brandName */
                                         output dataset dsDealer):
        define variable oFilter as JsonObject no-undo.
        define variable cBrand as character no-undo.
        define variable cDealerCode as character no-undo.
        define variable iLoop as integer no-undo.
        define variable lIncludeReps as logical no-undo.       
         
        define buffer lbTenant for Tenant.
        define buffer lbDealer for Dealer.
        define buffer lbAddressDetail for AddressDetail.
        define buffer lbState for State.
        define buffer lbContactDetail for ContactDetail.
        define buffer lbSalesrep for Salesrep.
        define buffer lbDepartment for Department.
        define buffer lbEmployee for Employee.

        dataset dsDealer:empty-dataset().
    
        oFilter = ParseFilter(filter).
        
        if not oFilter:Has('brandName') then
            undo, throw new AppError('Filter has no brandName property').        
        cBrand = oFilter:GetCharacter('brandName').

        if oFilter:Has('includeReps') then
            lIncludeReps = oFilter:GetLogical('includeReps').
        else
            lIncludeReps = false.

        find lbTenant where lbTenant.Name eq cBrand no-lock no-error.
        for each lbDealer where
                 lbDealer.TenantId eq lbTenant.TenantId 
                 no-lock:
            create eDealer.
            assign eDealer.DealerId = lbDealer.DealerId
                   eDealer.Code = lbDealer.Code
                   eDealer.Name = lbDealer.Name
                   eDealer.Brand = lbTenant.Name.
            
            find lbAddressDetail where
                 lbAddressDetail.AddressDetailId eq lbDealer.StreetAddressId
                 no-lock no-error.
            if available lbAddressDetail then
                assign eDealer.StreetAddress = lbAddressDetail.AddressLine1 + ','
                                       + lbAddressDetail.AddressLine2 + ','
                                       + lbAddressDetail.City + ','
                                       + lbAddressDetail.PostalCode + ' '
                                       + lbAddressDetail.State + ','
                                       + lbAddressDetail.CountryCode
                      /* make pretty */                                       
                      eDealer.StreetAddress = replace(eDealer.StreetAddress, ',,', ',')                                       
                      eDealer.StreetAddress = trim(eDealer.StreetAddress, ',')
                      
                      eDealer.Location = lbAddressDetail.City + ','
                                       + lbAddressDetail.PostalCode + ' '
                                       + lbAddressDetail.State
                      
                      /* make pretty */
                      eDealer.Location = replace(eDealer.Location, ',,', ',')                                       
                      eDealer.Location = trim(eDealer.Location, ',')
                      .
                                              
            find lbContactDetail where
                 lbContactDetail.ContactDetailId eq lbDealer.SalesEmailContactId
                 no-lock no-error.
            if available lbContactDetail then
                eDealer.SalesEmail = lbContactDetail.Detail. 
                
            find lbContactDetail where
                 lbContactDetail.ContactDetailId eq lbDealer.InfoEmailContactId
                 no-lock no-error.
            if available lbContactDetail then
                eDealer.InfoEmail = lbContactDetail.Detail. 
                
            find lbContactDetail where
                 lbContactDetail.ContactDetailId eq lbDealer.SwitchboardPhoneNumberId
                 no-lock no-error.
            if available lbContactDetail then
                eDealer.PhoneNumber = lbContactDetail.Detail.
        
            if lIncludeReps then
            for each lbDepartment where
                     lbDepartment.TenantId eq lbDealer.TenantId and
                     lbDepartment.Name eq 'sales'
                     no-lock,
                each lbEmployee where
                     lbEmployee.TenantId eq lbDepartment.TenantId and
                     lbEmployee.DepartmentId eq lbDepartment.DepartmentId and
                     lbEmployee.DealerId eq lbDealer.DealerId
                     no-lock,
                each lbSalesrep where
                     lbSalesrep.TenantId eq lbEmployee.TenantId and
                     lbSalesrep.EmployeeId eq lbEmployee.EmployeeId
                     no-lock:
                create eSalesrep.
                assign eSalesrep.DealerId = eDealer.DealerId
                       eSalesrep.Code = lbSalesrep.Code
                       eSalesrep.Region = lbSalesrep.SalesRegion
                       eSalesrep.Quota = lbSalesrep.AnnualQuota. 
            end.
        end.
        
        catch oAppError as AppError:
            message '[ERROR] ' + oAppError:ReturnValue.
            do iLoop = 1 to oAppError:NumMessages:
                message '[ERROR] ' + oAppError:GetMessage(iLoop).
            end.
        end catch.
        
        catch oError as Error:
            do iLoop = 1 to oError:NumMessages:
                message '[ERROR] ' + oError:GetMessage(iLoop).
            end.
        end catch.
    end method.
end class.
