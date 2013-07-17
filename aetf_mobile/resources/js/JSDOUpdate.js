/* Version: 1.0.2 */
$t.JSDOUpdate = $t.createClass(null, {

    init: function(requestOptions) {
        this.__requestOptions = $.extend({}, requestOptions);
    },

    process: function(settings) {
        var status = 'error';

        if (this.__requestOptions.echo) 
            throw new Error("Echo not supported");

        var svc_jsdo = this.__requestOptions.service.jsdo;
        var tableName = this.__requestOptions.tableName;
        var theid;
        var datarec;

        if (tableName == undefined) 
            tableName = svc_jsdo._dataProperty;

        var datarec = svc_jsdo[tableName]._recFromDataObject(settings.data);
        theid = datarec._id;


        var jsrow = svc_jsdo[tableName].findById(theid);

        if (jsrow != undefined) {
            jsrow.assign(datarec);
            
            /* before sending the request, save it away so we execute
               only the function for this DataSource */
            var beforeCreateUpdateFn = function (jsdo, jsrecord, request) {
                jsdo[tableName].unsubscribe('beforeCreate', beforeCreateUpdateFn);
                jsdo[tableName].unsubscribe('beforeUpdate', beforeCreateUpdateFn);
                settings.request = request;
            };
            
           var afterCreateUpdateFn = function(jsdo, record, success, request) {
               
                /* if not for the same request saved away on the before
                   create/update fn, just return */
                if (request != settings.request)
                    return;
               
               /* unsubscribe so this fn doesn't execute for some other
                  Tiggr.DataSource event */               
               jsdo[tableName].unsubscribe('afterCreate', afterCreateUpdateFn);
               jsdo[tableName].unsubscribe('afterUpdate', afterCreateUpdateFn);
               
               if (success) {
                   settings.success(request.results);
               } else {                        
                   var cError = settings.service.normalizeError(request);
                   settings.error(request.xhr, cError);						
               }
               settings.complete(request.xhr);
           };

            svc_jsdo[tableName].subscribe('beforeCreate', beforeCreateUpdateFn);
            svc_jsdo[tableName].subscribe('beforeUpdate', beforeCreateUpdateFn);
            svc_jsdo[tableName].subscribe('afterCreate', afterCreateUpdateFn);
            svc_jsdo[tableName].subscribe('afterUpdate', afterCreateUpdateFn);
            svc_jsdo.saveChanges();

            return;
        } else             
            settings.error(null, 'Row not found');

        settings.complete(null, status);
    }

});
