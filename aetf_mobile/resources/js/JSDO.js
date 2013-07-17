/* Version: 1.0.2 */
$t.JSDO = $t.createClass(null, {

    init: function(requestOptions) {
        this.pdsession = null;
        this.jsdo = null;
        this.__requestOptions = $.extend({}, requestOptions);        
        this.serviceSettings = this.__requestOptions.serviceSettings;
        
        this.normalizeError = function (request) {        
           var cError = "";                    
            /* try to get the error string. First try to get an					
               _error object, otherwise see if the error came					
               as a string in the body. If nothing is set, then					
               just get the native statusTest */
            if (request.results && request.results._errors && request.results._errors.length > 0)					   
                cError = request.results._errors[0]._errorMsg;                 				
            if (cError == "" && request.xhr.responseText.substring(0,6) != "<html>") 					
                cError = request.xhr.responseText;						
            if (cError == "")
                cError = request.xhr.statusText;					
            return cError;			
         };
    },

    process: function(settings) {
        var status = 'error';

        if (this.__requestOptions.echo) {
            throw new Error ("Echo not supported");		
        } else {
            this.jsdo = new progress.data.JSDO({
                name: this.serviceSettings.resourceName
            });
            
            settings.success();
            status = 'success';
        }
        settings.complete(null, status);
    }
});
