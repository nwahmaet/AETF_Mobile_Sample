/* Version: 1.0.2 */
$t.JSDOInvoke = $t.createClass(null, {
		
    init : function(requestOptions) {
        this.__requestOptions = $.extend({}, requestOptions);
    },
		
    process : function(settings) {
        if (this.__requestOptions.echo) 		
            throw new Error ("Echo not supported");			
        
        var svc_jsdo = this.__requestOptions.service.jsdo;
        var methodName = this.__requestOptions.methodName;  
        
        /* before sending the request, save it away so we execute
           only the function for this DataSource */
        var beforeInvokeFn = function (jsdo, request) {
            jsdo.unsubscribe('beforeInvoke', methodName, beforeInvokeFn);
            settings.request = request;
        };
        
        var afterInvokeFn = function(jsdo, success, request) {
            
            /* if not for the same request saved away on the before
               invoke fn, just return */
            if (request != settings.request)
                return;   
            
            /* unsubscribe so this fn doesn't execute for some other
               Tiggr.DataSource event */                
            jsdo.unsubscribe('afterInvoke', methodName, afterInvokeFn);
            
            var status = 'success';
            if (success) {
                var data;
                if (request.response == undefined)
                    data = request.results;
                else
                    data = request.response;
                settings.success(data);
            } else {
                status = 'error';                
                var cError = settings.service.normalizeError(request);
                
                settings.error(request.xhr, cError);
            }
            settings.complete(request.xhr, status);
        };
        svc_jsdo.subscribe('beforeInvoke', methodName, beforeInvokeFn);
        svc_jsdo.subscribe('afterInvoke', methodName, afterInvokeFn);
        svc_jsdo[methodName](settings.data);            
    } 

});
	