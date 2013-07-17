/* Version: 1.0.2 */
$t.JSDOCreate = $t.createClass(null, {
    
    init : function(requestOptions) {
        this.__requestOptions = $.extend({}, requestOptions);
    },
    
    process : function(settings) {
        var status = 'error';		
        
        if (this.__requestOptions.echo) {
            throw new Error ("Echo not supported");		
        } else {							
            var svc_jsdo = this.__requestOptions.service.jsdo;			
            var tableName = this.__requestOptions.tableName;				
            var jsrow;												
            
            if (tableName == undefined)				
                tableName = svc_jsdo._dataProperty;					
            
            jsrow = svc_jsdo[tableName].add();
            
            if (jsrow != undefined) {					
                status = 'success';							
                var data = svc_jsdo[tableName]._recToDataObject(jsrow.data, false);
                
                settings.success(data);
            }
            else					
                settings.error(null, 'Failed to add record');				
        }
        settings.complete(null, status);										
    } 
});
