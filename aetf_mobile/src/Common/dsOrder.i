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
    File        : dsCustomer.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : pjudge
    Created     : Wed Feb 29 15:18:39 EST 2012
    Notes       :
  ----------------------------------------------------------------------*/
define temp-table eOrder no-undo before-table beOrder
    field OrderNum      as integer
    field OrderId       as character
    field OrderDate     as date
    field EnteredDate   as datetime
    field FromEmail     as logical

    field CustomerNum   as integer
    field CustomerName  as character
    field CustomerPO    as character
    
    field OrderAmount   as decimal
    field OrderStatus   as character
    field Instructions  as character
    
    field SalesrepCode  as character
    field DealerCode    as character
    
    index idx1 as primary unique Orderid
    index idx2 as unique OrderNum.

define temp-table eOrderLine no-undo before-table beOrderLine
    field OrderId           as character
    field LineNum           as integer
    field Price             as decimal
    field Quantity          as integer
    field Discount          as integer
    field ItemId            as character
    field OrderLineStatus   as character
    field FinishedItemId    as character
    index idx1 as primary unique OrderId LineNum.

define temp-table eFinishedItem no-undo before-table beFinishedItem
    field FinishedItemId as character
    field ItemId as character
    field StatusDate as datetime
    field FinishedItemStatus as character
    field ExternalId as character   /* This is likely to be the VIN */
    index idx1 as primary unique FinishedItemId.

define temp-table eComponentItem no-undo before-table beComponentItem
    field ItemId as character
    field FinishedItemId as character
    field Quantity as decimal
    index idx1 as primary unique FinishedItemId ItemId 
    index idx2 FinishedItemId
    .

define temp-table eItem no-undo before-table beItem
    field ItemId as character
    field ItemNum as integer
    field ItemName as character
    field ItemType as character
    field Description as character
    field Price as decimal
    index idx1 as primary unique ItemId
    index idx2 as unique ItemNum
    .

/* manually populate eItem for eOrderLine, eFinishedItem */
define dataset dsOrder for eOrder, eOrderLine, eFinishedItem, eItem, eComponentItem
    data-relation for eOrder, eOrderLine relation-fields (OrderId, OrderId)
    data-relation for eOrderLine, eFinishedItem relation-fields (FinishedItemId, FinishedItemId)
    data-relation for eFinishedItem, eComponentItem relation-fields (FinishedItemId, FinishedItemId)
    data-relation for eComponentItem, eItem relation-field(ItemId, ItemId)
    .
    
    
    
    
