/* Version: 1.0.2 */
$t.JSDORow = $t.createClass(null, {
		
   init : function(requestOptions) {
            this.__requestOptions = $.extend({}, requestOptions);
        },
		
        process : function(settings) {
            var status = 'error';
            if (this.__requestOptions.echo) {
                throw new Error ("Echo not supported");		
            } else {									
                var svc_jsdo = this.__requestOptions.service.jsdo
                var theid = 	settings.data.id;								
                var tableName = this.__requestOptions.tableName;				
                
                if (tableName == undefined)
                    tableName = svc_jsdo._dataProperty;				
                
                jsrow = svc_jsdo[tableName].findById(theid);
                if (jsrow != undefined)				
                {								
                    var data = svc_jsdo[tableName]._recToDataObject(jsrow.data, true);
                    
                    settings.success(data);																
                    status = 'success';
                }
                else					
                    settings.error(null, 'Row not found');
            }
            settings.complete(null, status);					
       } 
    });
    