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
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="SecurityTokenService", URI="/SecurityTokenService", schemaName="", schemaFile="").
 /*------------------------------------------------------------------------
    File        : SecurityTokenService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Mon Jan 21 20:52:06 EST 2013
    Notes       : 
  ----------------------------------------------------------------------*/
routine-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Lang.AppError.
using Progress.Lang.Error.

class SecurityTokenService: 
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/Login", alias="", mediaType="application/json").
    method public void Login (input  pcUserName as character,
                              input  pcDomain as character,
                              input  pcPassword as character,
                              output pcUserContext as character):
        define variable oUserContext as JsonObject no-undo.
        define variable oErrorMessages as JsonArray no-undo.
        define variable cUserDomain as character no-undo.
        define variable cContextId as longchar no-undo.
        define variable hClientPrincipal as handle no-undo.
        define variable cFilename as character no-undo.
        define variable cClientPrincipal as longchar no-undo.
        define variable iMsgLoop as integer no-undo.
        
        define buffer lbUser for ApplicationUser.
        define buffer lbTenant for Tenant.
        
        oUserContext = new JsonObject().
        oUserContext:Add('error', false).
                        
        /* validate login credentials */
        cUserDomain = substitute('Customer.&1', pcDomain).
        
        find lbUser where
             lbUser.LoginName eq pcUserName and
             lbUser.LoginDomain eq cUserDomain
             no-lock no-error.
        if not available lbUser then
            undo, throw new AppError(substitute('Invalid username &1 for domain &2', pcUserName, cUserDomain)).    
        
        if lbUser.Password ne encode(pcPassword) then
            undo, throw new AppError(substitute('Invalid password for user &1', pcUserName)).
        
        do transaction:
            find current lbUser exclusive-lock.
            assign lbUser.LastLoginDate = now.
            
            find lbTenant where lbTenant.TenantId eq lbUser.TenantId no-lock no-error.
            
            create client-principal hClientPrincipal.
            hClientPrincipal:initialize(
                substitute('&1@&2', pcUserName, lc(lbTenant.Name)),
                guid(generate-uuid),
                ?,
                pcPassword).
            
            hClientPrincipal:seal(substitute('&1::&2', 'TABLE-ApplicationUser', lbTenant.TenantId)).
            /* Perform a validate-seal() first, since the errors thrown from here are more
               meaningful than errors trown from the set-client() call. */
            hClientPrincipal:validate-seal().
            security-policy:set-client(hClientPrincipal).

            cFilename = session:temp-dir + hClientPrincipal:session-id + '.ClientPrincipal.ser'.
            cClientPrincipal = base64-encode(hClientPrincipal:export-principal()). 
            copy-lob cClientPrincipal to file cFilename.
        end.    /* transaction */
        
        oUserContext:Add('CCID', hClientPrincipal:session-id).
        oUserContext:Add('TenantId', lbTenant.TenantId).
        oUserContext:Add('TenantName', lbTenant.Name).
        oUserContext:Add('LoginDomain', lbUser.LoginDomain).
        
        if lbUser.CustomerId gt '' then AddCustomerContext(oUserContext, buffer lbUser).
        if lbUser.EmployeeId gt '' then AddEmployeeContext(oUserContext, buffer lbUser).
        
        /* softly, softly */
        catch oAppError as AppError :
            oUserContext:Set('error', true).
        
            oErrorMessages = new JsonArray().
            oUserContext:Add('messages', oErrorMessages).
            
            oErrorMessages:Add(oAppError:ReturnValue).
            
            do iMsgLoop = 1 to oAppError:NumMessages:
                oErrorMessages:Add(oAppError:GetMessage(iMsgLoop)).
            end.
        end catch.
        
        catch oError as Error:
            oUserContext:Set('error', true).
            
            oErrorMessages = new JsonArray().
            oUserContext:Add('messages', oErrorMessages).
            
            do iMsgLoop = 1 to oError:NumMessages:
                oErrorMessages:Add(oError:GetMessage(iMsgLoop)).
            end.
        end catch.
        
        finally:
            define variable lcUserContext as longchar no-undo.
            /* [PJ] workaround for OE00219403 */
            oUserContext:Write(input-output lcUserContext).
            pcUserContext = string(lcUserContext).
        end finally.
    end method.

    method private void AddCustomerContext(input poContext as JsonObject, buffer pbUser for ApplicationUser):
        define buffer lbCustomer for Customer.
        define buffer lbContactDetail for ContactDetail.
        define buffer lbCustomerContact for CustomerContact.
        define buffer lbContactType for ContactType.

        find lbCustomer where
             lbCustomer.CustomerId eq pbUser.CustomerId and
             lbCustomer.TenantId eq pbUser.TenantId
             no-lock no-error.
        
        poContext:Add('UserType', 'Customer').
        poContext:Add('CustNum', lbCustomer.CustNum).
        poContext:Add('CreditLimit', lbCustomer.CreditLimit).
        poContext:Add('Name', lbCustomer.Name).
                
        find lbContactType where lbContactType.Name eq 'email-home' no-lock.
        find lbCustomerContact where
             lbCustomerContact.CustomerId eq lbCustomer.CustomerId and
             lbCustomerContact.TenantId eq lbCustomer.TenantId and
             lbCustomerContact.ContactType eq lbContactType.Name
             no-lock no-error.                 
        if available lbCustomerContact then
        find lbContactDetail where
             lbContactDetail.ContactDetailId eq lbCustomerContact.ContactDetailId
             no-lock no-error.
        if available lbContactDetail then
            poContext:Add('CustomerEmailHome', lbContactDetail.Detail).
    end method.

    method private void AddEmployeeContext(input poContext as JsonObject, buffer pbUser for ApplicationUser):
        define buffer lbEmployee for Employee.
        define buffer lbSalesrep for Salesrep.
        define buffer lbDealer for Dealer.

        poContext:Add('UserType', 'Employee').
        
        find first lbEmployee where
                   lbEmployee.TenantId = pbUser.TenantId and
                   lbEmployee.EmployeeId = pbUser.EmployeeId
                   no-lock no-error.
        if available lbEmployee then
            find first lbDealer where
                       lbDealer.TenantId = pbUser.TenantId and 
                       lbDealer.DealerId = lbEmployee.DealerId
                       no-lock no-error.
        if available lbDealer then
        do:
            poContext:Add('DealerName', lbDealer.Name).
            poContext:Add('DealerCode', lbDealer.Code). 
        end.               
        
        find first lbSalesrep where
                   lbSalesrep.TenantId = pbUser.TenantId and 
                   lbSalesrep.EmployeeId = lbEmployee.EmployeeId
                   no-lock no-error.
        if available lbSalesrep then
            poContext:Add('SalesRepCode', lbSalesRep.Code).
    end method.

    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/ValidateSession", alias="", mediaType="application/json").
    method public void ValidateSession(input  pcUserContextId as character,
                                       output pcResult as character):
        define variable oResult as JsonObject no-undo.
        define variable oErrorMessages  as JsonArray no-undo.
        define variable hClientPrincipal as handle no-undo.
        define variable cFilename as character no-undo.
        define variable cClientPrincipal as longchar no-undo.
        define variable mClientPrincipal as memptr no-undo.
        define variable rClientPrincipal as raw no-undo.
        define variable iMsgLoop as integer no-undo.
        
        oResult = new JsonObject().
        oResult:Add('error', false).
        
        cFilename = search(string(session:temp-dir + pcUserContextId + '.ClientPrincipal.ser')).
        if not cFilename eq ? then
        do:
            copy-lob file cFilename to cClientPrincipal.
            
            if cClientPrincipal ne '' then
            do:
                create client-principal hClientPrincipal.
                mClientPrincipal = base64-decode(cClientPrincipal).
                rClientPrincipal = get-bytes(mClientPrincipal, 1, get-size(mClientPrincipal)).
                hClientPrincipal:import-principal(rClientPrincipal).
            end.
        end.    
        
        if valid-handle(hClientPrincipal) then
            security-policy:set-client(hClientPrincipal).
        
        /** -- error handling -- **/
        catch oError as Progress.Lang.Error:
            oResult:Set('error', true).
            oErrorMessages = new JsonArray().
            oResult:Add('messages', oErrorMessages).
            
            do iMsgLoop = 1 to oError:NumMessages:
                oErrorMessages:Add(oError:GetMessage(iMsgLoop)).
            end.
        end catch.
        finally:
            set-size(mClientPrincipal) = 0.
            
            /* [PJ] workaround for OE00219403 */
            define variable lcResult as longchar no-undo.
            oResult:Write(input-output lcResult).
            pcResult = string(lcResult).
        end finally.        
    end method.
    
     @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
     @progress.service.resourceMapping(type="REST", operation="invoke", URI="/Logout", alias="", mediaType="application/json").
     method public void Logout (input  pcUserContextId as character,
                                output pcResult as character):
        
        define variable oResult as JsonObject no-undo.
        define variable oErrorMessages  as JsonArray no-undo.
        define variable hClientPrincipal as handle no-undo.
        define variable cFilename as character no-undo.
        define variable cClientPrincipal as longchar no-undo.
        define variable mClientPrincipal as memptr no-undo.
        define variable rClientPrincipal as raw no-undo.
        define variable iMsgLoop as integer no-undo.
        
        oResult = new JsonObject().
        oResult:Add('error', false).
        
        cFilename = search(string(session:temp-dir + pcUserContextId + '.ClientPrincipal.ser')).
        if not cFilename eq ? then
        do:
            copy-lob file cFilename to cClientPrincipal.
            
            if cClientPrincipal ne '' then
            do:
                mClientPrincipal = base64-decode(cClientPrincipal).
                rClientPrincipal = get-bytes(mClientPrincipal, 1, get-size(mClientPrincipal)).
                create client-principal hClientPrincipal.
                hClientPrincipal:import-principal(rClientPrincipal).        
            end.
        end.
        
        if valid-handle(hClientPrincipal) then
        do:
            hClientPrincipal:logout().
            os-delete value(cFilename).
        end.
        
        /** -- error handling -- **/
        catch oError as Progress.Lang.Error:
            oResult:Set('error', true).
            oErrorMessages = new JsonArray().
            oResult:Add('messages', oErrorMessages).
            
            do iMsgLoop = 1 to oError:NumMessages:
                oErrorMessages:Add(oError:GetMessage(iMsgLoop)).
            end.
        end catch.
        finally:
            set-size(mClientPrincipal) = 0.
            
            /* [PJ] workaround for OE00219403 */
            define variable lcResult as longchar no-undo.
            oResult:Write(input-output lcResult).
            pcResult = string(lcResult).
        end finally.         
     end method.
end class.
