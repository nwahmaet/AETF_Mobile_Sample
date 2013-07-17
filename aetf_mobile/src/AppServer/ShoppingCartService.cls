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
    File        : ShoppingCartService
    Syntax      : 
    Author(s)   : pjudge
    Created     : Wed Jan 09 14:34:52 EST 2013
    Notes       : 
  ----------------------------------------------------------------------*/
@program FILE(name="ShoppingCartService.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="ShoppingCartService", URI="/Cart", schemaName="dsShoppingCart", schemaFile="AETF Mobile Sample/src/AppServer/ShoppingCartService.cls").

routine-level on error undo, throw.

using OpenEdge.BusinessRules.DecisionService.
using OpenEdge.BusinessRules.RulesServerConnection.
using OpenEdge.BusinessRules.RulesServerConnectionParameters.

using Progress.Json.ObjectModel.ObjectModelParser.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Lang.AppError.
using Progress.Lang.Error.

class ShoppingCartService inherits BusinessEntity:
    {OpenEdge/BusinessRules/ttRulesMessage.i}

    define private variable moDecisionService as DecisionService no-undo.

    define static public property Instance as ShoppingCartService no-undo
        get():
            if not valid-object(ShoppingCartService:Instance) then
            do:
                ShoppingCartService:Instance = new ShoppingCartService().
                ShoppingCartService:Instance:Initialize().
            end.
            
            return ShoppingCartService:Instance.
        end get.
        private  set.
    
    {dsShoppingCart.i}
    
    constructor private ShoppingCartService (  ):
        super ().
    end constructor.
    
    method public void Initialize():
        define variable oParamData as JsonObject no-undo.
        define variable oParams as RulesServerConnectionParameters no-undo.
        define variable oServerConnection as RulesServerConnection no-undo.
                
        oParamData = cast(new ObjectModelParser():ParseFile('cfg/config.json'), JsonObject).
        
        oParams = new RulesServerConnectionParameters(oParamData:GetJsonObject('RulesServer')).
        oServerConnection = new RulesServerConnection(oParams).
        
        /* Use the latest version of the ShoppingCartDiscount DecisionService */
        moDecisionService = new DecisionService(oServerConnection, 'ShoppingCartDiscount').
    end method.

    method public void Destroy():
    end method.
    
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json"). 
    method public void ReadShoppingCartService(input filter as character, /* brandName, custNum */
                                               output dataset dsShoppingCart):
        define variable oFilter as JsonObject no-undo.
        define variable cBrand  as character no-undo.
        define variable iCustNum as integer no-undo.
        define variable iLoop as integer no-undo.
        define variable cOrderId as character no-undo.
        
        define buffer lbTenant for Tenant.
        define buffer lbCustomer for Customer.
        
        define variable dLineTotal as decimal no-undo.
        
        dataset dsShoppingCart:empty-dataset().
        
        oFilter = ParseFilter(filter).
        
        if not oFilter:Has('brandName') then
            undo, throw new AppError('Filter has no brandName property').
        cBrand = oFilter:GetCharacter('brandName').

        if not oFilter:Has('custNum') then
            undo, throw new AppError('Filter has no custNum property').        
        iCustNum = oFilter:GetInteger('custNum').

        /* defaults to all unordered carts */
        cOrderId = ?.
        if oFilter:Has('orderId') then  
            cOrderId = oFilter:GetCharacter('orderId').
        
        find lbTenant where lbTenant.Name eq cBrand no-lock.
        find lbCustomer where 
             lbCustomer.TenantId eq lbTenant.TenantId and
             lbCustomer.CustNum eq iCustNum
             no-lock.

        LoadCartData(substitute(' lbShoppingCart.TenantId eq &1 and
                             lbShoppingCart.CustomerId eq &2 and
                             lbShoppingCart.OrderId eq &3',
                  lbCustomer.TenantId,
                  lbCustomer.CustomerId,
                  cOrderId)).

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

    method private void LoadCartData(input pcFilter as character):
        define buffer lbTenant for Tenant.
        define buffer lbCustomer for Customer.
        define buffer lbShoppingCart for ShoppingCart.
        define buffer lbShoppingCartOption for ShoppingCartOption.
        define buffer lbItem for Item.
        define buffer lbOptionItem for Item.
        define buffer lbItemType for ItemType.
        define buffer lbOrder for Order.
        define buffer eShoppingCart for eShoppingCart.
        define buffer eShoppingCartOption for eShoppingCartOption.
        
        define query qryCart for lbShoppingCart, lbTenant, lbCustomer, lbItem.

        query qryCart:query-prepare(' for each lbShoppingCart where ' + pcFilter + ' no-lock, '
                                    + 'each lbTenant where '
                                    + '     lbTenant.TenantId eq lbShoppingCart.TenantId '
                                    + '     no-lock, '
                                    + 'each lbCustomer where '
                                    + '     lbCustomer.TenantId eq lbShoppingCart.TenantId and '
                                    + '     lbCustomer.CustomerId eq lbShoppingCart.CustomerId '
                                    + '     no-lock, '
                                    + 'each lbItem where '
                                    + '     lbItem.TenantId eq lbShoppingCart.TenantId and '
                                    + '     lbItem.ItemId eq lbShoppingCart.ItemId '
                                    + '     no-lock ').

        query qryCart:query-open().
        query qryCart:get-first(no-lock).

        do while not query qryCart:query-off-end:
            create eShoppingCart.
            assign eShoppingCart.Brand = lbTenant.Name
                   eShoppingCart.Id = lbShoppingCart.ShoppingCartId
                   
                   eShoppingCart.EnteredDate = lbShoppingCart.EnteredDate
                   eShoppingCart.Discount = lbShoppingCart.Discount
                   eShoppingCart.Price = lbShoppingCart.Price
                   eShoppingCart.Qty = lbShoppingCart.Qty
                
                   /* FK values set separately */
                   eShoppingCart.CustomerNum = lbCustomer.CustNum
                   eShoppingCart.ItemId = lbItem.ItemId
                   eShoppingCart.DealerId = lbShoppingCart.DealerId.
            
            create eCustomer.
            buffer-copy lbCustomer to eCustomer
                assign eCustomer.CustomerNum = lbCustomer.CustNum
                       eCustomer.CustomerName = lbCustomer.Name
                       eCustomer.Discount = decimal(lbCustomer.Discount).

            find lbOrder where
                 lbOrder.TenantId eq lbShoppingCart.TenantId and
                 lbOrder.OrderId eq lbShoppingCart.OrderId
                 no-lock no-error.
            if available lbOrder then
                eShoppingCart.OrderNum = lbOrder.OrderNum.
                
            for each lbShoppingCartOption where
                     lbShoppingCartOption.TenantId eq lbShoppingCart.TenantId and
                     lbShoppingCartOption.ShoppingCartId eq lbShoppingCart.ShoppingCartId
                     no-lock,
                each lbOptionItem where
                     lbOptionItem.TenantId eq lbShoppingCartOption.TenantId and
                     lbOptionItem.ItemId eq lbShoppingCartOption.ItemId
                     no-lock,
              first lbItemType where
                    lbItemType.ItemTypeId eq lbOptionItem.ItemTypeId
                    no-lock: 
                create eShoppingCartOption.                         
                assign eShoppingCartOption.Id = lbShoppingCartOption.ShoppingCartId
                       eShoppingCartOption.ItemId = lbShoppingCartOption.ItemId
                       eShoppingCartOption.ItemType = lbItemType.Name
                       eShoppingCartOption.ItemNum = lbOptionItem.ItemNum
                       eShoppingCartOption.ItemName = lbOptionItem.ItemName
                       eShoppingCartOption.Description = lbOptionItem.Description
                       eShoppingCartOption.Quantity = lbShoppingCartOption.Qty
                       eShoppingCartOption.Price = lbShoppingCartOption.Price 
                       eShoppingCartOption.Discount = lbShoppingCartOption.Discount
                       .
            end.
            
            UpdateFKFields(buffer eShoppingCart).                   
        end.    
    end method.
    
    method private void UpdateFKFields(buffer pbCart for eShoppingCart):
        define buffer Tenant for Tenant. 
        define buffer Order for Order.
        define buffer OrderLine for OrderLine.
        define buffer StatusDetail for StatusDetail.
        define buffer Salesrep for Salesrep.
        define buffer Employee for Employee.
        define buffer Dealer for Dealer.
        define buffer Item for Item.
        define buffer ItemType for ItemType.
        
        define variable dLineTotal as decimal no-undo.
            
        find Tenant where Tenant.Name eq pbCart.Brand no-lock.
        
        find Dealer where
             Dealer.TenantId eq Tenant.TenantId and
             Dealer.DealerId eq pbCart.DealerId
             no-lock.
        assign pbCart.DealerCode = Dealer.Name.
                           
        find Order where
             Order.TenantId eq Tenant.TenantId and
             Order.OrderNum eq pbCart.OrderNum
             no-lock no-error.
        if available Order then
        do:
            for each OrderLine where
                     OrderLine.TenantId eq Order.TenantId and
                     OrderLine.OrderId eq Order.OrderId
                     no-lock:
                dLineTotal = OrderLine.Price * OrderLine.Qty.
                if OrderLine.Discount gt 0 then
                    dLineTotal = dLineTotal - (OrderLine.Discount * dLineTotal / 100).
                pbCart.OrderAmount = pbCart.OrderAmount + dLineTotal.
            end.
            
            find StatusDetail where
                 StatusDetail.StatusDetailId eq Order.StatusId
                 no-lock.
            
            find Salesrep where
                 Salesrep.TenantId eq Order.TenantId and
                 Salesrep.SalesrepId eq Order.SalesrepId
                 no-lock.
            assign pbCart.OrderNum = Order.OrderNum
                   pbCart.OrderStatus = StatusDetail.Description
                   pbCart.Instructions = Order.Instructions
                   pbCart.SalesrepCode = Salesrep.Code
                   .
        end.
            
        find Item where 
             Item.TenantId eq Tenant.TenantId and
             Item.ItemId eq pbCart.ItemId
             no-lock.
        find ItemType where
             ItemType.ItemTypeId eq Item.ItemTypeId
             no-lock.
        assign pbCart.ItemNum = Item.ItemNum
               pbCart.ItemName = Item.ItemName
               pbCart.ItemType = ItemType.Description
               pbCart.Description = Item.Description.
    end method.
    
    /*------------------------------------------------------------------------------
            Purpose: Create one or more new records                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/  
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="create", URI="", alias="", mediaType="application/json").
    method public void CreateShoppingCartService(input-output dataset dsShoppingCart):
        define variable iLoop as integer no-undo.
        define buffer lbTenant for Tenant.
        define buffer lbCustomer for Customer.
        define buffer lbShoppingCart for ShoppingCart.
        define buffer lbItemType for ItemType.
        define buffer lbItem for Item.
        define buffer lbOrder for Order.
        define buffer lbOrderLine for OrderLine.
        define buffer lbStatusDetail for StatusDetail. 
        define buffer lbDealer for Dealer.
        define buffer lbEmployee for Employee.
        define buffer lbSalesrep for Salesrep.
        
        define buffer eShoppingCart for eShoppingCart.
        
        for each eShoppingCart:
            find lbTenant where lbTenant.Name eq eShoppingCart.Brand no-lock.
            find lbCustomer where 
                 lbCustomer.TenantId eq lbTenant.TenantId and
                 lbCustomer.CustNum eq eShoppingCart.CustomerNum
                 no-lock.
            find lbItem where 
                 lbItem.TenantId eq lbTenant.TenantId and
                 lbItem.ItemId eq eShoppingCart.ItemId
                 no-lock.
            
            create lbShoppingCart.
            assign lbShoppingCart.ShoppingCartId = eShoppingCart.Id
                   lbShoppingCart.TenantId = lbTenant.TenantId
                   lbShoppingCart.CustomerId = lbCustomer.CustomerId
                   lbShoppingCart.DealerId = eShoppingCart.DealerId
                   
                   lbShoppingCart.ItemId = lbItem.ItemId
                   
                   lbShoppingCart.EnteredDate = eShoppingCart.EnteredDate
                   lbShoppingCart.Discount = eShoppingCart.Discount
                   lbShoppingCart.Qty = eShoppingCart.Qty
                   lbShoppingCart.Price = eShoppingCart.Price

                   lbShoppingCart.OrderId = ?
                   .
            /* since we're returning the same dataset, update any FK values */
            UpdateFKFields(buffer eShoppingCart).                   
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
    
    /*------------------------------------------------------------------------------
            Purpose:  Update one or more records                                                                  
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="update", URI="", alias="", mediaType="application/json").
    method public void UpdateShoppingCartService(input-output dataset dsShoppingCart):
        define variable iLoop as integer no-undo.
        
        define buffer lbTenant for Tenant.
        define buffer lbCustomer for Customer.
        define buffer lbShoppingCart for ShoppingCart.
        define buffer lbItem for Item.
        define buffer lbOrder for Order.
        
        define buffer eShoppingCart for eShoppingCart.

        for each eShoppingCart:
            find lbTenant where lbTenant.Name eq eShoppingCart.Brand no-lock.
            find lbShoppingCart where
                 lbShoppingCart.TenantId eq lbTenant.TenantId and
                 lbShoppingCart.ShoppingCartId eq eShoppingCart.Id
                 no-lock.
            
            if lbShoppingCart.OrderId ne ? then
            do:
                buffer eShoppingCart:error-string = 'Cannot modify cart items that have orders'.      
                next.
            end.
            
            find lbCustomer where 
                 lbCustomer.TenantId eq lbTenant.TenantId and
                 lbCustomer.CustNum eq eShoppingCart.CustomerNum
                 no-lock.
            find lbItem where 
                 lbItem.TenantId eq lbTenant.TenantId and
                 lbItem.ItemId eq eShoppingCart.ItemId
                 no-lock.
            
            find lbOrder where
                 lbOrder.TenantId eq lbTenant.TenantId and
                 lbOrder.OrderNum eq eShoppingCart.OrderNum
                 no-lock no-error.
            
            assign lbShoppingCart.CustomerId = lbCustomer.CustomerId
                   lbShoppingCart.ItemId = lbItem.ItemId
                   lbShoppingCart.Discount = eShoppingCart.Discount
                   lbShoppingCart.Qty = eShoppingCart.Qty
                   lbShoppingCart.Price = eShoppingCart.Price
                   lbShoppingCart.OrderId = lbOrder.OrderId when available lbOrder.
            
            /* since we're returning the same dataset, update any FK values */
            UpdateFKFields(buffer eShoppingCart).                   
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
    
    /*------------------------------------------------------------------------------
            Purpose:    Delete a record                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="delete", URI="", alias="", mediaType="application/json").
    method public void DeleteShoppingCartService(input-output dataset dsShoppingCart):
        define variable iLoop as integer no-undo.
                    
        define buffer lbTenant for Tenant.
        define buffer lbCustomer for Customer.
        define buffer lbShoppingCart for ShoppingCart.
        define buffer lbItem for Item.
        define buffer lbOrder for Order.

        for each eShoppingCart:
            if eShoppingCart.OrderNum ne 0 then
                undo, throw new AppError('Cannot modify cart items that have orders').
                
            find lbTenant where lbTenant.Name eq eShoppingCart.Brand no-lock.
            find lbShoppingCart where
                 lbShoppingCart.TenantId eq lbTenant.TenantId and
                 lbShoppingCart.ShoppingCartId eq eShoppingCart.Id
                 exclusive-lock no-wait.
            
            delete lbShoppingCart.    
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
    
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/CalculateDiscount", alias="", mediaType="application/json").
    method public void CalculateDiscount (input  pcBrand as character,
                                          input  pcShoppingCartId as character,
                                          output pcResult as longchar): 
        define variable iMsgLoop as integer no-undo.
        define variable oResult as JsonObject no-undo.
        define variable oMessages as JsonArray no-undo.
        define variable hAppData as handle.

        define buffer lbTenant for Tenant.        

        oResult = new JsonObject().
        oResult:Add('shoppingCartId', pcShoppingCartId).
        oResult:Add('error', false).

        find lbTenant where lbTenant.Name eq pcBrand no-lock.

        LoadCartData(substitute(' lbShoppingCart.TenantId eq &1 and
                                  lbShoppingCart.ShoppingCartId eq &2 ',
                  lbTenant.TenantId,
                  pcShoppingCartId)).

        /* default no discount */
        oResult:Add('discountPercentage', decimal(0)).
        
        /* calculate discount via OERULES */
        hAppData = dataset dsShoppingCart:handle.
        moDecisionService:InvokeService(input-output dataset-handle hAppData by-reference).
        
        find first eShoppingCart where eShoppingCart.Id eq pcShoppingCartId.
        oResult:Set('discountPercentage', eShoppingCart.Discount).
        
        oMessages = new JsonArray().
        oResult:Add('ruleMessages', oMessages).
        oMessages:Read(buffer RulesMessage:handle).
        
        return.
        catch oAppError as AppError :
            oResult:Set('error', true).
        
            oMessages = new JsonArray().
            oResult:Add('messages', oMessages).
            
            oMessages:Add(oAppError:ReturnValue).
            
            do iMsgLoop = 1 to oAppError:NumMessages:
                oMessages:Add(oAppError:GetMessage(iMsgLoop)).
            end.
        end catch.
        
        catch oError as Error:
            oResult:Set('error', true).
            
            oMessages = new JsonArray().
            oResult:Add('messages', oMessages).
            
            do iMsgLoop = 1 to oError:NumMessages:
                oMessages:Add(oError:GetMessage(iMsgLoop)).
            end.
        end catch.
        
        finally:
            oResult:Write(input-output pcResult).
        end finally.
    end method.
    
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="invoke", URI="/CaptureOrder", alias="", mediaType="application/json").
    method public void CaptureOrder (input pcBrand as character,
                                     input pcShoppingCartId as character,
                                     output pcResult as character): /* JSON */
        define variable iOrderNumber as integer no-undo.
        define variable cFinishedItemId as character no-undo.
        define variable cOrderId as character no-undo.
        define variable iMsgLoop as integer no-undo.
        define variable oResult as JsonObject no-undo.
        define variable oErrorMessages as JsonArray no-undo.
        
        define buffer lbTenant for Tenant.
        define buffer lbCustomer for Customer.
        define buffer lbShoppingCart for ShoppingCart.
        define buffer lbCart for ShoppingCart.
        define buffer lbCartOption for ShoppingCartOption.
        define buffer lbItem for Item.
        define buffer lbOrder for Order.
        define buffer lbStatusDetail for StatusDetail. 

        oResult = new JsonObject().
        oResult:Add('shoppingCartId', pcShoppingCartId).
        oResult:Add('error', false).
        
        find lbStatusDetail where lbStatusDetail.Code eq 'ORDER-NEW' no-lock no-error.
        find lbTenant where lbTenant.Name eq pcBrand no-lock.

        find lbShoppingCart where 
             lbShoppingCart.TenantId eq lbTenant.TenantId and
             lbShoppingCart.ShoppingCartId eq pcShoppingCartId
             no-lock no-error.
        do transaction on error undo, throw:
            iOrderNumber = GetNextOrderNum(lbTenant.TenantId).                
            cOrderId = CreateOrder(
                            iOrderNumber,
                            lbShoppingCart.CustomerId,
                            lbShoppingCart.DealerId,
                            lbTenant.TenantId,
                            lbStatusDetail.StatusDetailId).
            cFinishedItemId = CreateFinishedItem(
                                lbShoppingCart.ItemId,
                                lbTenant.TenantId,
                                lbStatusDetail.StatusDetailId).
            
            for each lbCartOption where
                     lbCartOption.TenantId eq lbShoppingCart.TenantId and
                     lbCartOption.ShoppingCartId eq lbShoppingCart.ShoppingCartId
                     no-lock:
                CreateComponentItem(
                    cFinishedItemId, 
                    lbCartOption.ItemId,
                    lbCartOption.Qty,
                    lbCartOption.TenantId).
            end.
            
            CreateOrderLine(
                    cOrderId,
                    cFinishedItemId, 
                    lbShoppingCart.Qty,
                    lbShoppingCart.ItemId,
                    lbShoppingCart.TenantId,
                    lbStatusDetail.StatusDetailId).
            
            find lbCart where
                 rowid(lbCart) eq rowid(lbShoppingCart)
                 exclusive-lock no-error.
            lbCart.OrderId = cOrderId.
        end.    /* transaction */
        
        /* update ShoppingCart with OrderId */
        oResult:Add('orderNum', iOrderNumber).
         
        catch oAppError as AppError :
            oResult:Set('error', true).
        
            oErrorMessages = new JsonArray().
            oResult:Add('messages', oErrorMessages).
            
            oErrorMessages:Add(oAppError:ReturnValue).
            
            do iMsgLoop = 1 to oAppError:NumMessages:
                oErrorMessages:Add(oAppError:GetMessage(iMsgLoop)).
            end.
        end catch.
        
        catch oError as Error:
            oResult:Set('error', true).
            
            oErrorMessages = new JsonArray().
            oResult:Add('messages', oErrorMessages).
            
            do iMsgLoop = 1 to oError:NumMessages:
                oErrorMessages:Add(oError:GetMessage(iMsgLoop)).
            end.
        end catch.
        
        finally:
            /* [PJ] workaround for OE00219403 */
            define variable lcResult as longchar no-undo.
            oResult:Write(input-output lcResult).
            pcResult = string(lcResult).
        end finally.
    end method.
    
    method private integer GetNextOrderNum(input pcTenantId as character):
        define variable iOrderNum as integer no-undo.
        
        define buffer lbOrder for Order.
        define query qryOrder for lbOrder.
        open query qryOrder 
            preselect each lbOrder where
                           lbOrder.TenantId eq pcTenantId
                           no-lock
                           by lbOrder.OrderNum descending.
        query qryOrder:get-first().
        if available lbOrder then
            iOrderNum = lbOrder.OrderNum + 1.
        else
            iOrderNum = 1.
        
        close query qryOrder.
        
        return iOrderNum.
    end method.
    
    method private character CreateOrder (input piOrderNum as integer,
                                          input pcCustomerId as character,
                                          input pcDealerId as character,
                                          input pcTenantId as character,
                                          input pcStatusId as character):
        define buffer lbOrder for Order.
        define buffer lbCustomer for Customer.
        define buffer lbSalesrep for Salesrep.
        define buffer lbDealer for Dealer.
        define buffer lbDepartment for Department.
        define buffer lbEmployee for Employee.
        
        create lbOrder.
        assign lbOrder.TenantId = pcTenantId
               lbOrder.OrderNum = piOrderNum
               lbOrder.OrderId = guid(generate-uuid)
               lbOrder.EnteredDate = now
               lbOrder.OrderDate = today
               lbOrder.Instructions = ''
               lbOrder.StatusId = pcStatusId.
            
        find lbCustomer where
             lbCustomer.TenantId eq lbOrder.TenantId and
             lbCustomer.CustomerId eq pcCustomerId
             no-lock no-error.
        if available lbCustomer then
            lbOrder.CustomerId = lbCustomer.CustomerId.
    
        /* add default */
        find lbDealer where
             lbDealer.TenantId eq lbOrder.TenantId and
             lbDealer.Code eq pcDealerId
             no-lock no-error.
        if available lbDealer then
            find first lbDepartment where
                       lbDepartment.TenantId eq lbDealer.TenantId and
                       lbDepartment.Name eq 'sales'
                       no-lock no-error.
        if available lbDepartment then
            find first lbEmployee where
                       lbEmployee.DealerId eq lbDealer.DealerId and
                       lbEmployee.DepartmentId eq lbDepartment.DepartmentId and
                       lbEmployee.TenantId eq lbDealer.TenantId
                       no-lock no-error.
        if available lbEmployee then                           
            find first lbSalesrep where
                       lbSalesrep.EmployeeId eq lbEmployee.EmployeeId and
                       lbSalesrep.TenantId eq lbEmployee.TenantId
                       no-lock no-error.
        if available lbSalesrep then
            lbOrder.SalesrepId = lbSalesrep.SalesrepId.
        
        return lbOrder.OrderId.
    end method.
    
    method private void CreateComponentItem (input pcFinishedItemId as character,
                                             input pcItemId as character,
                                             input pdQuantity as decimal,
                                             input pcTenantId as character):    
        define buffer lbComponentItem for ComponentItem.
            
        create lbComponentItem.
        assign lbComponentItem.ItemId = pcItemId
               lbComponentItem.TenantId = pcTenantId
               lbComponentItem.FinishedItemId = pcFinishedItemId
               lbComponentItem.Qty = lbComponentItem.Qty + pdQuantity.
    end method.
    
    method private character CreateFinishedItem (input pcModelId as character,
                                                 input pcTenantId as character,
                                                 input pcStatusId as character):
        define buffer lbFinishedItem for FinishedItem.
        define buffer lbOrderLine for OrderLine.
        
        create lbFinishedItem.
        assign lbFinishedItem.FinishedItemId = guid(generate-uuid)
               lbFinishedItem.TenantId = pcTenantId
               lbFinishedItem.ItemId = pcModelId
               lbFinishedItem.StatusDate = now
               lbFinishedItem.StatusId = pcStatusId.
               
        return lbFinishedItem.FinishedItemId.           
    end method.    
        
    method private void CreateOrderLine (input pcOrderId as character,
                                         input pcFinishedItemId as character,
                                         input piQuantity as integer,
                                         input pcModelId as character,
                                         input pcTenantId as character,
                                         input pcStatusId as character):
        define buffer lbOrderLine for OrderLine.
        define buffer lbComponentItem for ComponentItem.
        define buffer lbFinishedItem for FinishedItem.
        define buffer lbItem for Item.
        
        create lbOrderLine.
        assign
            lbOrderLine.OrderId = pcOrderId
            lbOrderLine.TenantId = pcTenantId
            lbOrderLine.LineNum = 1
            lbOrderLine.Qty = piQuantity
            lbOrderLine.ItemId = pcModelId
            lbOrderLine.FinishedItemId = pcFinishedItemId
            lbOrderLine.StatusId = pcStatusId.
        
        find lbFinishedItem where
             lbFinishedItem.TenantId eq lbOrderLine.TenantId and
             lbFinishedItem.FinishedItemId eq lbOrderLine.FinishedItemId
             no-lock no-error.
        find lbItem where
             lbItem.ItemId eq lbFinishedItem.ItemId and
             lbItem.TenantId eq lbFinishedItem.TenantId
             no-lock no-error.
        if available lbItem then         
            lbOrderLine.Price = lbOrderLine.Price + lbItem.Price.
    
        for each lbComponentItem where
                 lbComponentItem.TenantId eq lbOrderLine.TenantId and
                 lbComponentItem.FinishedItemId eq lbOrderLine.FinishedItemId 
                 no-lock,
           first lbItem where
                 lbItem.ItemId eq lbComponentItem.ItemId and
                 lbItem.TenantId eq lbComponentItem.TenantId
                 no-lock:
            lbOrderLine.Price = lbOrderLine.Price + lbItem.Price.
        end.
    end method.    
        
end class.
