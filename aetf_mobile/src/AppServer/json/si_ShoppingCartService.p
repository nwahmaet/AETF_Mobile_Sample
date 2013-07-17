
/*------------------------------------------------------------------------
    File        : json/si_ShoppingCartService.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed May 01 13:21:03 EDT 2013
    Notes       :
  ----------------------------------------------------------------------*/
/* ***************************  Definitions  ************************** */
routine-level on error undo, throw.

{dsShoppingCart.i}

/* ***************************  Main Block  *************************** */
procedure ReadShoppingCartService:
    define input parameter filter as character no-undo. /* brandName, custNum */
    define output parameter dataset for dsShoppingCart.
    
    ShoppingCartService:Instance:ReadShoppingCartService(filter, output dataset dsShoppingCart by-reference).
end procedure.

procedure CreateShoppingCartService:
    define input-output parameter dataset for dsShoppingCart.
    
    ShoppingCartService:Instance:CreateShoppingCartService(input-output dataset dsShoppingCart by-reference).
end procedure.

procedure UpdateShoppingCartService:
    define input-output parameter dataset for dsShoppingCart.
    
    ShoppingCartService:Instance:UpdateShoppingCartService(input-output dataset dsShoppingCart by-reference).
end procedure.
    
procedure DeleteShoppingCartService:
    define input-output parameter dataset for dsShoppingCart.
    
    ShoppingCartService:Instance:DeleteShoppingCartService(input-output dataset dsShoppingCart by-reference).
end procedure.
        
procedure CalculateDiscount:
    define input  parameter pcBrand as character no-undo.
    define input  parameter pcShoppingCartId as character no-undo.
    define output parameter pcResult as longchar no-undo.
        
    ShoppingCartService:Instance:CalculateDiscount(pcBrand, pcShoppingCartId, output pcResult).
end procedure.

procedure CaptureOrder:
    define input  parameter pcBrand as character no-undo.
    define input  parameter pcShoppingCartId as character no-undo.
    define output parameter pcResult as character no-undo.
    
    ShoppingCartService:Instance:CaptureOrder(input pcBrand, input pcShoppingCartId, output pcResult).
end procedure.
