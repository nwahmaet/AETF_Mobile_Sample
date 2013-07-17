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
    File        : dsBrandData.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Jan 10 13:06:26 EST 2013
    Notes       :
  ----------------------------------------------------------------------*/
/* Each eVehicle is an Item, actually */
define temp-table eVehicle no-undo
    field Brand as character
    field ItemId as character
    field VehicleName as character
    field Description as character
    field Price as decimal
    field VehicleType as character
    field StyleCode as character
    field Style as character
    field ImgURL as character
    index idx1 as primary unique ItemId
    .

define temp-table eItem no-undo
    field ItemId as character
    field ItemNum as integer
    field ItemName as character
    field ItemType as character
    field Description as character
    field Price as decimal
    index idx1 as primary unique ItemNum
    .

define temp-table eItemOption no-undo
    field ItemId as character
    field ItemNum as integer
    field ChildItemId as character
    field ChildItemNum as integer
    field ChildType as character
    field Quantity as decimal
    field StandardOption as logical
    index idx2 ChildItemNum
    .

define dataset dsVehicleOptions for eVehicle, eItem, eItemOption
    /* get the options for the vehicles */
    data-relation for eVehicle, eItemOption relation-fields (ItemId, ItemId)
    /* single-level series of items and options */
    data-relation for eItemOption, eItem relation-fields (ChildItemId, ItemId)
    .
