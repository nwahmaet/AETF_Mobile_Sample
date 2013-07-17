/* Version: 1.0.2 */
$t.JSDODelete = $t.createClass(null, {

    init: function(requestOptions) {
        this.__requestOptions = $.extend({}, requestOptions);
    },

    process: function(settings) {
        if (this.__requestOptions.echo)     
            throw new Error("Echo not supported");

        var svc_jsdo = this.__requestOptions.service.jsdo;
        var tableName = this.__requestOptions.tableName;        
        var theid;

        if (tableName == undefined) 
            tableName = svc_jsdo._dataProperty;

        var datarec = svc_jsdo[tableName]._recFromDataObject(settings.data);
        theid = datarec._id;

        var jsrow = svc_jsdo[tableName].findById(theid);
        if (jsrow != undefined) { 
            
            /* before sending the request, save it away so we execute
               only the function for this DataSource */
            var beforeDeleteFn = function (jsdo, jsrecord, request) {
                jsdo[tableName].unsubscribe('beforeDelete', beforeDeleteFn);
                settings.request = request;
            };
            
            var afterDeleteFn = function(jsdo, record, success, request) {
                
                /* if not for the same request saved away on the before
                   delete fn, just return */
                if (request != settings.request)
                    return;
                
                /* unsubscribe so this fn doesn't execute for some other
                   Tiggr.DataSource event */
                jsdo[tableName].unsubscribe('afterDelete', afterDeleteFn);
                
                if (success) {
                    settings.success(request.results);
                } else {                    
                    var cError = settings.service.normalizeError(request);

                    settings.error(request.xhr, cError);
                }
                settings.complete(request.xhr);
            };                
            jsrow.remove();
            svc_jsdo[tableName].subscribe('beforeDelete', beforeDeleteFn);
            svc_jsdo[tableName].subscribe('afterDelete', afterDeleteFn);
            svc_jsdo.saveChanges();
        } else             
            settings.error(null, 'Row not found');
    }

});
