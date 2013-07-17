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
    File        : dsDealer.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Jan 10 13:21:55 EST 2013
    Notes       :
  ----------------------------------------------------------------------*/
    define private temp-table eDealer no-undo
        field Brand as character
        field DealerId as character
        field Code as character
        field Name as character
        field SalesEmail as character
        field InfoEmail as character
        field StreetAddress as character
        /* since StreetAddress may not actuall exist, add Location field for use in real-life geolocation/map lookups */
        field Location as character  
        field PhoneNumber as character
        index idx1 as primary unique DealerId
        index idx2 as unique Code.
    
    define private temp-table eSalesrep no-undo
        field DealerId as character
        field Code as character
        field Quota as decimal
        field Region as character
        index idx1 as primary unique DealerId Code.
        .
    
    define dataset dsDealer for eDealer, eSalesrep
       data-relation for eDealer, eSalesrep relation-fields(DealerId, DealerId).
       
