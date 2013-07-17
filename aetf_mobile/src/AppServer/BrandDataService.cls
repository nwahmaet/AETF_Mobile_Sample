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
/** ------------------------------------------------------------------------
    File        : BrandDataService
    Syntax      : 
    Author(s)   : pjudge
    Created     : Thu Jan 10 13:08:15 EST 2013
    Notes       : 
  ----------------------------------------------------------------------*/
    
@program FILE(name="BrandDataService.cls", module="AppServer").
@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
@progress.service.resource FILE(name="BrandDataService", URI="/BrandData", schemaName="dsVehicleOptions", schemaFile="AETF Mobile Sample/src/AppServer/BrandDataService.cls").

routine-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Lang.Error.
using Progress.Lang.AppError.

class BrandDataService  inherits BusinessEntity:
    {dsVehicleOptions.i}
    
    constructor public BrandDataService (  ):
        super ().
    end constructor.
    
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    @progress.service.resourceMapping(type="REST", operation="read", URI="?filter=~{filter~}", alias="", mediaType="application/json"). 
    method public void ReadBrandDataService(input filter as character, /* brandName, optional-VehicleId */
                                            output dataset dsVehicleOptions):
        define variable oFilter as JsonObject no-undo.
        define variable cBrand as character no-undo.
        define variable cVehicleId as character no-undo.
        define variable iLoop as integer no-undo.
        define variable oOptionTypes as JsonArray no-undo.
        define variable cTypes as character extent no-undo.
        
        define buffer lbTenant for Tenant.

        dataset dsVehicleOptions:empty-dataset().

        oFilter = ParseFilter(filter).
        
        if not oFilter:Has('brandName') then
            undo, throw new AppError('Filter has no brandName property').        
        cBrand = oFilter:GetCharacter('brandName').
        
        find lbTenant where lbTenant.Name eq cBrand no-lock no-error.
        
        if oFilter:Has('optionTypes') then
        do:
            oOptionTypes = oFilter:GetJsonArray('optionTypes').
            cTypes = oOptionTypes:GetCharacter(1, oOptionTypes:Length).
        end.
        else
            assign extent(cTypes) = 1
                   cTypes[1] = '*'. 
        
        if oFilter:Has('vehicleId') then
            GetVehicle(oFilter:GetCharacter('vehicleId'), buffer lbTenant, cTypes, '').
        else
        do:
            GetModels('Vehicle-Compact', 'Compact Cars', buffer lbTenant, cTypes).
            GetModels('Vehicle-Truck', 'Trucks & Vans', buffer lbTenant, cTypes).
            GetModels('Vehicle-Commercial', 'Trucks & Vans', buffer lbTenant, cTypes).
            GetModels('Vehicle-Sedan', 'Sedans', buffer lbTenant, cTypes).
            GetModels('Vehicle-SUV', 'Crossovers', buffer lbTenant, cTypes).
            GetModels('Vehicle-Crossover', 'Crossovers', buffer lbTenant, cTypes).
            GetModels('Vehicle-Convertible', 'Premium Vehicles', buffer lbTenant, cTypes).
            GetModels('Vehicle-Coupe', 'Premium Vehicles', buffer lbTenant, cTypes).
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
    
    method private void GetModels(input  pcType as character,
                                  input  pcStyle as character,
                                  buffer pbTenant for Tenant,
                                  input  pcTypes as character extent):
        define buffer lbVehicle for Item.
        define buffer lbItemType for ItemType.
        
        find lbItemType where lbItemType.Name eq pcType no-lock no-error.
        
        for each lbVehicle where
                 lbVehicle.ItemTypeId eq lbItemType.ItemTypeId and 
                 lbVehicle.TenantId eq pbTenant.TenantId
                 no-lock:
            GetVehicle(lbVehicle.ItemId, buffer pbTenant, pcTypes, pcStyle).                    
        end.
    end method.
    
    method private void GetVehicle(input  pcVehicleId as character,
                                   buffer pbTenant for Tenant,
                                   input  pcOptionTypes as character extent,
                                   input  pcStyle as character): 
        define buffer lbVehicle for Item.
        define buffer lbItemType for ItemType.
        
        find lbVehicle where
             lbVehicle.ItemId eq pcVehicleId and 
             lbVehicle.TenantId eq pbTenant.TenantId
             no-lock.
        find first lbItemType where 
                   lbItemType.ItemTypeId eq lbVehicle.ItemTypeId
                   no-lock.
        
        if pcStyle eq '' then
            pcStyle = entry(2, lbItemType.Name, '-').
             
        create eVehicle.
        assign eVehicle.ItemId = lbVehicle.ItemId
               eVehicle.VehicleName = lbVehicle.ItemName
               eVehicle.Brand = pbTenant.Name
               eVehicle.VehicleType = lbItemType.Name
               eVehicle.Price = lbVehicle.Price
               
               eVehicle.Description = /*lbVehicle.Description */ 'Vestibulum eu nunc quis eros interdum porttitor nec eu sem. Nulla suscipit augue at tortor mattis pulvinar. Praesent luctus suscipit.'                   
               eVehicle.Style = pcStyle
               eVehicle.StyleCode = replace(pcStyle, ' ', '')
               eVehicle.StyleCode = replace(eVehicle.StyleCode, '~&', '')
               eVehicle.ImgURL = substitute('&1.png', lc(entry(2, eVehicle.VehicleType, '-'))).
        
        GetVehicleOptions(buffer lbVehicle, pcOptionTypes).
    end method.
    
    method private void GetVehicleOptions (buffer pbVehicle for Item,
                                           input pcOptionTypes as character extent):
        define buffer lbItem for Item.
        define buffer childItemItem for Item.
        define buffer childItemItemType  for ItemType.
        define buffer lbItemOption for ItemOption.
        
        for each lbItemOption where
                 lbItemOption.TenantId eq pbVehicle.TenantId and
                 lbItemOption.ItemId eq pbVehicle.ItemId
                 no-lock,
            each childItemItem where
                 childItemItem.TenantId eq lbItemOption.TenantId and
                 childItemItem.ItemId eq lbItemOption.ChildItemId
                 no-lock,
            first childItemItemType where
                  childItemItemType.ItemTypeId eq childItemItem.ItemTypeId
                  no-lock:
            create eItemOption.
            assign eItemOption.StandardOption = lbItemOption.StandardOption
                   eItemOption.Quantity = lbItemOption.Quantity
                   
                   eItemOption.ItemId = pbVehicle.ItemId
                   eItemOption.ItemNum = pbVehicle.ItemNum
                   
                   eItemOption.ChildItemId = childItemItem.ItemId
                   eItemOption.ChildItemNum = childItemItem.ItemNum
                   eItemOption.ChildType = childItemItemType.Name.
                   
            if not can-find(eItem where eItem.ItemId eq childItemItem.ItemId) then
            do:
                create eItem.
                assign eItem.ItemId = childItemItem.ItemId
                       eItem.ItemName = childItemItem.ItemName
                       eItem.ItemNum = childItemItem.ItemNum
                       eItem.ItemType = childItemItemType.Name                           
                       eItem.Price = childItemItem.Price
                       eItem.Description  = childItemItem.Description.
            end.
        end.                          
        
    end method.
end class.
