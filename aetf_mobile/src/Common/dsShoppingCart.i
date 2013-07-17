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
    File        : CommondsShoppingCart.i
    Description : 
    Author(s)   : pjudge
    Created     : Wednesday, January 09, 2013
    Notes       :
  ----------------------------------------------------------------------*/
define temp-table eShoppingCart no-undo before-table beShoppingCart
    field Brand          as character
    field Id             as character
    field EnteredDate    as datetime-tz
    field Discount       as decimal
    field Price          as decimal
    field Qty            as integer
    /*field CartStatus     as character*/
    
    field CustomerNum   as integer
    field CustomerName  as character
    
    field ItemId        as character
    field ItemNum       as integer
    field ItemName      as character
    field ItemType      as character
    field Description   as character
    
    field OrderNum      as integer
    field OrderAmount   as decimal
    field OrderStatus   as character
    field Instructions  as character
    field SalesrepCode  as character
    field DealerCode    as character
    field DealerId      as character
    
    index idx1 as primary unique CustomerNum ItemId
    index idx2 CustomerNum EnteredDate.
    
define temp-table eShoppingCartOption no-undo before-table beShoppingCartOption
    field Id            as character           /* shopping cart ID */
    field ItemId        as character
    field ItemNum       as integer
    field ItemName      as character
    field ItemType      as character
    field Description   as character
    field Quantity as decimal
    field Price as decimal
    field Discount as decimal
    index idx1 as primary unique Id ItemId
    index idx2 Id ItemType
    .
    
define temp-table eCustomer no-undo before-table beCustomer
    field CustomerNum   as integer
    field CustomerName  as character
    field CreditLimit   as decimal 
    field Balance       as decimal
    field Terms         as character
    field Discount      as decimal
    index idx1 as primary unique CustomerNum
    . 

define dataset dsShoppingCart for eShoppingCart, eShoppingCartOption, eCustomer
    data-relation CartOption for eShoppingCart, eShoppingCartOption relation-fields(Id, Id) nested
    data-relation CartCustomer for eShoppingCart, eCustomer relation-fields(CustomerNum, CustomerNum) nested
    .
