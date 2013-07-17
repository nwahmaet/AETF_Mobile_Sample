/**
 * Custom JavaScript functions for VehicleOrderApp
 * 
 */
// don't define this twice
if (!AETF) {AETF = {};};

(function() {
  // 'namespaces'
  AETF.vehicleorder = {};
  AETF.vehicleorder.dealer = {};
  AETF.vehicleorder.accessories = {};

  // private vars here
  var geocoder = new google.maps.Geocoder();
    
  // functions
  AETF.vehicleorder.init = function() { };

  /**  
   * Loop through dealers and create map markers for each one
   * */
  AETF.vehicleorder.dealer.loadDealers = function() {
    // GMaps needs upper-case letters
    var letter = 'A';
    var map = Tiggzi('dealer_map').gmap;
      
    VehicleOrderService_DealerService_JSDO.jsdo
      .eDealer
      .foreach(function(dealer) {
          AETF.vehicleorder.dealer.addMarker(dealer.data, map, letter);
          letter = AETF.util.nextChar(letter);
        });
  };

  /**
   * Once a dealer is selected, update the eShoppingCart
   */
  AETF.vehicleorder.dealer.selectDealer = function(element) {
    // From the cart, set the current dealer
    // The service call to VehicleOrderService_ShoppingCartService_eShoppingCart_Row
    // has already selected the correct record, so we don't need to
    VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCart
        .assign({"DealerId"   : $(element).val(),
                 "DealerCode" : $(element).find('option:selected').text()});      
  }; 

  AETF.vehicleorder.dealer.setSelectedDealer = function(dlrId) {
   var dlrList =  Tiggzi('dealer_list');
  // set the value of the Dealer drop-down/select
    dlrList.find(" > option[value='" + dlrId+ "']")
           .attr('selected', 'selected');
    dlrList.selectmenu('refresh');  
      
    AETF.vehicleorder.dealer.selectDealer(dlrList);
  };
    
  AETF.vehicleorder.dealer.infoWindows = [];
    
  AETF.vehicleorder.dealer.addMarker = function(dealer, dealer_map, letter) {
    // Uses dealer.Location because it's got a better chance of actually
    // existing (dealer.StreetAddress is basically made up
    geocoder.geocode({address : dealer.Location},
        function(results, status) {
          if (status == google.maps.GeocoderStatus.OK) {
              var marker = new google.maps.Marker(              
                  {title: dealer.Name,
                   position: results[0].geometry.location,
                   map : dealer_map,
                   icon : "http://maps.google.com/mapfiles/marker" + letter + ".png"                   
                  }
              );

            var contentString = '<div id="content">'
                + '<div id="siteNotice">'
                + '</div>'
                + '<h2 id="firstHeading" class="firstHeading">'
                + dealer.Name
                + '</h2>'
                + '<div id="bodyContent">'
                + '<p><table border="0" bordercolor="#FFCC00" width="100%" cellpadding="3" cellspacing="3">'
                + '<tr><td>Address</td><td>' + dealer.StreetAddress
                + '</td></tr>'
                + '<tr><td>Email Sales</td><td><a href="mailto:'
                + dealer.SalesEmail + '">' + dealer.SalesEmail
                + '</a> </td></tr>' + '<tr><td>Phone</td><td><a href="tel:'
                + dealer.PhoneNumber + '">' + dealer.PhoneNumber
                + '</a></td></tr>' 
                + '<tr><td><button type="button" onclick="AETF.vehicleorder.dealer.setSelectedDealer(\''+dealer.DealerId+'\');">'
                + 'Choose ' + dealer.Name + '</button>'
                + '<button type="button" onclick="console.log(\'no-op\');">Get directions</button></td>'
                + '</tr>'
                + '</table></p>' + '</div></div>';
                
            var infowindow = new google.maps.InfoWindow({content : contentString });
              
            // store reference to keep for later so that we can remove when another marker clicked            
            AETF.vehicleorder.dealer.infoWindows.push(infowindow);
                                
            google.maps.event.addListener(marker, 'click', function() {
                //automatically close other infowindows when a new one is opened
                while (AETF.vehicleorder.dealer.infoWindows.length > 0) {
                    var iw = AETF.vehicleorder.dealer.infoWindows.pop();
                    iw.close();
                  };                
                infowindow.open(dealer_map, marker);
            });
          } else {
            alert("Geocode was not successful for the following reason: "+ status);};
        });
  };

  AETF.vehicleorder.accessories.addInput = function(inputType, inputName, item, option,html) {
    html = html + '<input type="'+inputType+'" name="' + inputName 
        + '" id="'+inputType+'-' + item.data.ItemNum 
        + '" value="' + item.data.ItemId
        + '" data-option-id="' + item.data.ItemId 
        + '" data-option-price="' + item.data.Price 
        + '" data-option-name="' + item.data.ItemName
        + '" data-option-num="' + item.data.ItemNum 
        + '" data-option-type="' + item.data.ItemType
        + '" data-option-qty="' + option.data.Quantity
        + '" ';

    if (option.data.StandardOption) {html = html + ' checked="checked" ';};

    html = html + '/>' + '<label for="'+inputType+'-' + item.data.ItemNum + '">'
        + '<div data-role="tiggr_label" class="labelClass mobilelabel7 ">'
        + item.data.Description + '</div>'
        + '<div data-role="tiggr_label" class="labelClass mobilelabel8 ">'
        + accounting.formatMoney(item.data.Price) + '</div>' + '</label>';

    return html;
  };

  AETF.vehicleorder.accessories.loadInterior = function() {
    Tiggzi('interior_accessories').empty();
    Tiggzi('interior_trimmaterial').empty();
    Tiggzi('interior_trimcolour').empty();

    // add accessories to UI

    // build up the UI widgets from item options
    var accessoryHtml = '<fieldset data-role="controlgroup">';
    var materialHtml = '<fieldset data-role="controlgroup">';
    var colourHtml = '<fieldset data-role="controlgroup">';

    // eVehicle should be available via service call and will filter the options
    VehicleOrderService_BrandDataService_JSDO.jsdo
        .eItemOption
        .foreach(function(itemOption) {
          // console.log(option);
          // Find the relevant Item, for the name,id and type
          var item = VehicleOrderService_BrandDataService_JSDO.jsdo
              .eItem
              .find(function(item) {
                return (itemOption.data.ChildItemId === item.data.ItemId);});

          if (itemOption.data.ChildType === "Accessories") {
            accessoryHtml = AETF.vehicleorder.accessories.addInput('checkbox', 'checkbox-accessories', item, itemOption, accessoryHtml);
          };
          if (itemOption.data.ChildType === "Trim-Material") {
            materialHtml = AETF.vehicleorder.accessories.addInput('radio', 'radio-trim-material', item, itemOption, materialHtml);
          };
          if (itemOption.data.ChildType === "Trim-Colour") {
            colourHtml = AETF.vehicleorder.accessories.addInput('radio', 'radio-trim-colour', item, itemOption, colourHtml);
          };
        });

    accessoryHtml = accessoryHtml + '</fieldset>';
    materialHtml = materialHtml + '</fieldset>';
    colourHtml = colourHtml + '</fieldset>';

    Tiggzi('interior_accessories').append(accessoryHtml);
    Tiggzi('interior_accessories').trigger("create");

    Tiggzi('interior_trimmaterial').append(materialHtml);
    Tiggzi('interior_trimmaterial').trigger("create");

    Tiggzi('interior_trimcolour').append(colourHtml);
    Tiggzi('interior_trimcolour').trigger("create");

    // now select from cart options
    // Cart should be available already
    VehicleOrderService_ShoppingCartService_JSDO.jsdo.eShoppingCart.record;

    // .findById(localStorage.getItem('cartId'));
    VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCartOption
        .foreach(function(cartOption) {
            
            
          if (cartOption.data.ItemType === "Accessories") {
            //$('input:checkbox[name=checkbox-accessories]').selectByValue(cartOption.data.ItemId);
            Tiggzi('checkbox-accessories')
                .find(" > option[value='" + cartOption.data.ItemId+ "']")
                .attr('selected', 'selected');
            };
          if (cartOption.data.ItemType === "Trim-Material") {
            //$('input:radio[name=radio-trim-material]').selectByValue(cartOption.data.ItemId);
            Tiggzi('radio-trim-material')
                .find(" > option[value='" + cartOption.data.ItemId+ "']")
                .attr('checked', 'checked');
          };
          if (cartOption.data.ItemType === "Trim-Colour") {
              console.log(cartOption.data);
            //$('input:radio[name=radio-trim-colour]').selectByValue(cartOption.data.ItemId);
            console.log(Tiggzi('radio-trim-colour').find(" > option[value='" + cartOption.data.ItemId+ "']"));
              
              Tiggzi('radio-trim-colour')
                .find(" > option[value='" + cartOption.data.ItemId+ "']")
                .attr('checked', 'checked');
          };
        });

    Tiggzi('interior_accessories').refresh();
    Tiggzi('interior_trimmaterial').refresh();
    Tiggzi('interior_trimcolour').refresh();
  };

  AETF.vehicleorder.accessories.loadExterior = function() {
    Tiggzi('exterior_moonroof').empty();
    Tiggzi('exterior_wheels').empty();
    Tiggzi('exterior_paintcolour').empty();

    // add accessories to UI
    // vars for new content
    var moonroofHtml = '<fieldset data-role="controlgroup">';
    var wheelsHtml = '<fieldset data-role="controlgroup">';
    var colourHtml = '<fieldset data-role="controlgroup">';

    // eVehicle should be available via service call and will filter the options
    VehicleOrderService_BrandDataService_JSDO.jsdo
        .eItemOption
        .foreach(function(option) {
          // console.log(option);
          // Find the relevant Item, for the name,id and type
          var item = VehicleOrderService_BrandDataService_JSDO.jsdo
              .eItem
              .find(function(item) {return (option.data.ChildItemId === item.data.ItemId);
              });

          if (option.data.ChildType === "Moonroof") {
            moonroofHtml = AETF.vehicleorder.accessories.addInput('radio', 'radio-moonroof', item, option, moonroofHtml);
          };
          if (option.data.ChildType === "Wheels") {
            wheelsHtml = AETF.vehicleorder.accessories.addInput('radio', 'radio-wheels', item, option, wheelsHtml);
          };
          if (option.data.ChildType === "Ext-Colour") {
            colourHtml = AETF.vehicleorder.accessories.addInput('radio', 'radio-ext-colour', item, option, colourHtml);
            };
        });

    moonroofHtml = moonroofHtml + '</fieldset>';
    wheelsHtml = wheelsHtml + '</fieldset>';
    colourHtml = colourHtml + '</fieldset>';

    Tiggzi('exterior_moonroof').append(moonroofHtml);
    Tiggzi('exterior_moonroof').trigger("create");

    Tiggzi('exterior_wheels').append(wheelsHtml);
    Tiggzi('exterior_wheels').trigger("create");

    Tiggzi('exterior_paintcolour').append(colourHtml);
    Tiggzi('exterior_paintcolour').trigger("create");

    // now select from cart options
    // .findById(localStorage.getItem('cartId'));
    VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCartOption
        .foreach(function(cartOption) {
          if (cartOption.data.ItemType === "Moonroof") {
            $('input:radio[name=radio-moonroof]').selectByValue(cartOption.data.ItemId);
          };
          if (cartOption.data.ItemType === "Wheels") {
            $('input:radio[name=radio-wheels]').selectByValue(cartOption.data.ItemId);
          };
          if (cartOption.data.ItemType === "Ext-Colour") {
            $('input:radio[name=radio-ext-colour]').selectByValue(cartOption.data.ItemId);
          };
        });
    Tiggzi('exterior_moonroof').refresh();
    Tiggzi('exterior_wheels').refresh();
    Tiggzi('exterior_paintcolour').refresh();
  };

  AETF.vehicleorder.updateCartTotal = function(cart) {
    // total up the cart price with all options, not just this page
    var cartTotal = +0.0;
    VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCartOption
        .foreach(function(sco) {
          var itemTotal = +0.0;
          itemTotal += (sco.data.Price * sco.data.Quantity);
          if (sco.data.Discount > 0) {
            itemTotal = itemTotal - (sco.data.Discount * itemTotal) / 100;};

          cartTotal += itemTotal;
        });

    var vehicle = VehicleOrderService_BrandDataService_JSDO.jsdo
        .eVehicle
        .findById(localStorage.getItem('vehicleId'));

    cartTotal = (vehicle.data.Price + cartTotal) * cart.data.Qty;
    if (cart.data.Discount > 0) {
      cartTotal = cartTotal - (cart.data.Discount * cartTotal) / 100;
    };

    cart.assign({"Price" : cartTotal});
  };

  AETF.vehicleorder.updateCartOptions = function(pageName) {
    var cartOptionTable = VehicleOrderService_ShoppingCartService_JSDO.jsdo
          .eShoppingCartOption;

    var shoppingCart = VehicleOrderService_ShoppingCartService_JSDO.jsdo
          .eShoppingCart.record; // returns JSRecord

    if (pageName === 'interior') {
      // delete all accessories options, since we don't know how many were
      // previously selected nor which ones
      cartOptionTable.foreach(function(removeOption) {
        if (removeOption.ItemType === "Accessories") {removeOption.remove();}
      });

      updateOptionFromUI("interior_accessories", shoppingCart.data.Id, "Accessories", true);
      updateOptionFromUI("interior_trimmaterial", shoppingCart.data.Id, "Trim-Material", false);
      updateOptionFromUI("interior_trimcolour", shoppingCart.data.Id, "Trim-Colour", false);
    } else if (pageName === 'exterior') {
      // add options from UI
      updateOptionFromUI("exterior_moonroof", shoppingCart.data.Id, "Moonroof", false);
      updateOptionFromUI("exterior_wheels", shoppingCart.data.Id, "Ext-Wheels", false);
      updateOptionFromUI("exterior_paintcolour", shoppingCart.data.Id, "Ext-Colour", false);
    };

    AETF.vehicleorder.updateCartTotal(shoppingCart);

    function updateOptionFromUI(widgetName, cartId, itemType, allowMultiple) {
      $('[dsid="' + widgetName + '"] input:checked ').each(function() {
        if (!allowMultiple) {
          // is there already a selected accessory?
          var optionRecord = cartOptionTable.find(function(sco) {
            return (sco.data.ItemType === itemType);
          });
        }
        ;
        // if not, create one
        if (!optionRecord) {
          optionRecord = cartOptionTable.add({
            "Id" : cartId,
            "ItemType" : itemType
          });
        };
          
        optionRecord.assign({
          "ItemId" : $(this).attr('data-option-id'),
          "Quantity" : $(this).attr('data-option-qty'),
          "Price" : $(this).attr('data-option-price'),
          "ItemType" : $(this).attr('data-option-type'),
          "ItemNum" : $(this).attr('data-option-num'),
          "ItemName" : $(this).attr('data-option-name')
        });
      });
    };
  }; // AETF.vehicleorder.updateCartOptions

  /**
   * selectVehicle fired when a particular vehicle style is selected
   */
  AETF.vehicleorder.selectVehicle = function(selectedElement) {
    // we always have a cart. explicitly get the cart here
    var cart = VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCart
        .findById(localStorage.getItem('cartId')); // returns JSRecord

    // if this is a different item in the cart, clear out the old contents,
    // and add new stuff
    if ($(selectedElement).attr('data-item-id') !== cart.data.ItemId) {
      // Find the vehicle record
      var vehicle = VehicleOrderService_BrandDataService_JSDO.jsdo
          .eVehicle
          .findById($(selectedElement).attr('data-vehicle-id'));

      cart.assign({
        "Price" : vehicle.data.Price,
        "ItemName" : vehicle.data.VehicleName,
        "ItemId" : vehicle.data.ItemId,
        "Qty" : 1,
        "ItemType" : vehicle.data.VehicleType
      });

      // remove cart options, if any exist
      VehicleOrderService_ShoppingCartService_JSDO.jsdo
          .eShoppingCartOption
          .foreach(function(cartOption) {
            // console.log(cartOption);
            // console.log('removing old option ' + cartOption.data.ItemName);
            cartOption.remove();
          });

      // add standard options to cart
      VehicleOrderService_BrandDataService_JSDO.jsdo
          .eItemOption
          .foreach(function(itemOption) {
            if (itemOption.data.StandardOption) {
              // find the eItem for the eItemOption. The foreach()
              // does this find by traversing the ProDataSet relations
              var item = VehicleOrderService_BrandDataService_JSDO.jsdo
                  .eItem.record;

              // console.log('adding std option=' + itemOption.data.ChildType +
              // ' ' + accounting.formatMoney(item.data.Price));
              VehicleOrderService_ShoppingCartService_JSDO.jsdo
                  .eShoppingCartOption
                  .add({
                    "Id" : cart.data.Id,
                    "ItemId" : itemOption.data.ChildItemId,
                    "Quantity" : itemOption.data.Quantity,
                    "ItemType" : itemOption.data.ChildType,
                    "ItemNum" : itemOption.data.ChildItemNum,
                    "Discount" : 0,
                    "Price" : item.data.Price
                  });
            };
          });
    };
  };

  /**
   * updates the vehicledetail page with info from the (updated) cart
   */
  AETF.vehicleorder.showCartDetail = function() {
    // we always have a cart. explicitly get the cart here
    var cart = VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCart
        .findById(localStorage.getItem('cartId')); // returns JSRecord

    // vehicle should already be selected/available
    var vehicle = VehicleOrderService_BrandDataService_JSDO.jsdo
        .eVehicle.record; // returns JSRecord

    // calculate and display the value of the selected accessories,
    // from then shopping cart options
    var intPrice = +0.0;
    var extPrice = +0.0;
    var itemTotal = +0.0;

    // This foreach() is implicitly filtered by the cart
    // we found above
    VehicleOrderService_ShoppingCartService_JSDO.jsdo
        .eShoppingCartOption
        .foreach(function(cartOption) {
          if (cartOption.data.ItemType === "Moonroof"
              || cartOption.data.ItemType === "Wheels"
              || cartOption.data.ItemType === "Ext-Colour") {
            itemTotal = (cartOption.data.Price * cartOption.data.Quantity);
            if (cartOption.data.Discount > 0) {
              itemTotal = itemTotal - (cartOption.data.Discount * itemTotal) / 100;};
            extPrice += itemTotal;
          };
          
          if (cartOption.data.ItemType === "Accessories"
              || cartOption.data.ItemType === "Trim-Material"
              || cartOption.data.ItemType === "Trim-Colour") {
            itemTotal = (cartOption.data.Price * cartOption.data.Quantity);
            if (cartOption.data.Discount > 0) {
              itemTotal = itemTotal - (cartOption.data.Discount * itemTotal) / 100;};
            intPrice += itemTotal;
          }; 
        });

    Tiggzi('detail_interior_price').text(accounting.formatMoney(intPrice));
    Tiggzi('detail_interior_price').refresh();
    
    Tiggzi('detail_exterior_price').text(accounting.formatMoney(extPrice));
    Tiggzi('detail_exterior_price').refresh();

    Tiggzi('detail_cart_total').text('Cart total ' + accounting.formatMoney(cart.data.Price));
    Tiggzi('detail_cart_total').refresh();

    Tiggzi('detail_dealer_name').text((cart.data.DealerCode === '' ? 'No dealer selected' : cart.data.DealerCode));
    Tiggzi('detail_dealer_name').refresh();  
  };
    
    AETF.vehicleorder.processActionResult = function() {
      var result = JSON.parse(localStorage.getItem('actionResult'));
        if (result != undefined ) {
            if (result.error) {
            Tiggzi('result_text').text(result.messages);            
            } else if (result.orderNum != undefined) {
            Tiggzi('result_text').text('Order '  + result.orderNum + ' created.');
            };
        };
    };    
})();
