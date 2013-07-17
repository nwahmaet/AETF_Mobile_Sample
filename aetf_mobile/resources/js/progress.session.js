/* Copyright (c) 2012-2013 by Progress Software Corporation       */
/*                                                           */
/* All rights reserved.  No part of this program or document */
/* may be  reproduced in  any form  or by  any means without */
/* permission in writing from PROGRESS Software Corporation. */

// Version: 11.2ALPHA
// Version: 11.2.0021

/*
 * progress.session.js
 */


(function () {
		
/* define these if not defined yet - they may already be defined if
    progress.js was included first */
if (typeof progress == 'undefined')
    progress = {};
if (typeof progress.data == 'undefined' )
    progress.data = {};

progress.data.ServicesManager = {};
progress.data.ServicesManager._services = [];    
progress.data.ServicesManager._resources = [];
progress.data.ServicesManager._data = [];
progress.data.ServicesManager._sessions = []; 
/*
 progress.data.ServicesManager.put = function(id, jsdo) {
    progress.data.ServicesManager._data[id] = jsdo;    
};
progress.data.ServicesManager.get = function(id) {
    return progress.data.ServicesManager._data[id];
};
*/

progress.data.ServicesManager.addResource = function(id, resource) {
	if (progress.data.ServicesManager._resources[id] == undefined) 
		progress.data.ServicesManager._resources[id] = resource;    
	else
		throw new Error( "A resource named '" + id + "' was already loaded.");
};
progress.data.ServicesManager.getResource = function(id) {
    return progress.data.ServicesManager._resources[id];
};
progress.data.ServicesManager.addService = function(id, service) {
	if (progress.data.ServicesManager._services[id] == undefined)
		progress.data.ServicesManager._services[id] = service;
	else
		throw new Error( "A service named '" + id + "' was already loaded.");
};
progress.data.ServicesManager.getService = function(id) {
    return progress.data.ServicesManager._services[id];
};
progress.data.ServicesManager.addSession = function(catalogURI, session) {
	if (progress.data.ServicesManager._sessions[catalogURI] == undefined)
		progress.data.ServicesManager._sessions[catalogURI] = session;
	else	
		throw new Error( "Cannot load catalog '" + catalogURI + "' multiple times.");
};
progress.data.ServicesManager.getSession = function(catalogURI) {
	try {
		return progress.data.ServicesManager._sessions[catalogURI];
	}
	catch( e ) {
		return null;
	}
};

/*
 * Scans URL for parameters of the form {name}
 * Returns array with the names
 */
function extractParamsFromURL(url) {
	var urlParams = [];
	if (typeof(url) == 'string') {
		var paramName = null;
		for (var i = 0; i < url.length; i++) {
			if (url.charAt(i) == '{') {
				paramName = "";
			}
			else if (url.charAt(i) == '}') {
				if (paramName)
					urlParams.push(paramName);
				paramName = null;
			}
			else if (paramName != null) {
				paramName += url.charAt(i);
			}
		}
	} 
	return urlParams;
}

/*
 * Adds the catalog.json file provided by the catalog parameter, which is a JSDO 
 * that has loaded the catalog
 */
progress.data.ServicesManager.addCatalog = function( services, session ) {
	if (!services) {
		throw new Error( "Cannot find 'services' property in catalog file" );
	}	
	if (services instanceof Array) {
		
		// first check if there are duplicates before we add them to our cache,
		// which only handles unique values
		for (var j=0;j<services.length;j++){
			// don't allow services with the same name across sessions
			if (progress.data.ServicesManager.getService(services[j].name) != undefined)
				throw new Error( "A service named '" + services[j].name + "' was already loaded.");
	
			var resources = services[j].resources;
			
			if (resources instanceof Array) {
				for (var i=0;i<resources.length;i++) {
					if (progress.data.ServicesManager.getResource(resources[i].name) != undefined)
						throw new Error( "A resource named '" + resources[i].name + "' was already loaded.");
				}				
			}
			else {
				throw new Error("Missing 'resources' array in catalog");				
			}
		}
		
		// TODO: Register services
		for (var j=0;j<services.length;j++){
			services[j]._session = session;
			this.addService( services[j].name, services[j] );               // Register the service
			var resources = services[j].resources;
			var baseAddress = services[j].address;
			if (resources instanceof Array) {
				for (var i=0;i<resources.length;i++) {
					var resource = resources[i];
					resource.fn = {};
					resource.service = services[j];       
					resources[i].url = baseAddress + resources[i].path;
					// Register resource 
					progress.data.ServicesManager.addResource(resources[i].name, resources[i]);

					// Process schema
					resource.fields = null;
					if (resource.schema) {
						resource.fields = {};
						resource._dataSetName = null;
                        resource.tempTableName = null;
						var properties = null;

						try {
							if (typeof resource.schema.properties != 'undefined') {
								var keys = Object.keys(resource.schema.properties);
								properties = resource.schema.properties;
								if (keys.length == 1) {
									if (typeof resource.schema.properties[keys[0]].properties != 'undefined') {
										// Schema corresponds to a DataSet
										resource._dataSetName = keys[0];
									}
									else if (typeof resource.schema.properties[keys[0]].items != 'undefined') {
										// Schema corresponds to a temp-table
										resource.dataProperty = keys[0];
										properties = resource.schema.properties[keys[0]].items.properties;
                                        resource.tempTableName = resource.dataProperty;
									}
								}
							}
							else {
								var keys = Object.keys(resource.schema);
								if (keys.length == 1) {
									resource.dataProperty = keys[0];
									if (typeof resource.schema[keys[0]].items != 'undefined') {
										// Catalog format correspond to Table Schema
										properties = resource.schema[keys[0]].items.properties;
                                        resource.tempTableName = resource.dataProperty;
									}
									else if (typeof resource.schema[keys[0]].properties != 'undefined') {
										// Catalog format correspond to DataSet Schema
										resource._dataSetName = keys[0];
										resource.dataProperty = null;
										properties = resource.schema;
									}
								}
							}
						}
						catch(e) {
							throw new Error("Error parsing catalog file.");
						}
						if (properties) {
							if (resource._dataSetName) {
								properties = properties[resource._dataSetName].properties;
								for (var tableName in properties) {
									resource.fields[tableName] = [];
									var tableProperties;
									if (properties[tableName].items
										&& properties[tableName].items.properties) {
										tableProperties = properties[tableName].items.properties;
									}
									else {
										tableProperties = properties[tableName].properties;
									}
									for (var field in tableProperties) {
										tableProperties[field].name = field;
										resource.fields[tableName].push(tableProperties[field]);	
									}
								}
							}
							else {
								var tableName = resource.dataProperty?resource.dataProperty:"";
								resource.fields[tableName] = [];
								for (var field in properties) {
									properties[field].name = field;
									resource.fields[tableName].push(properties[field]);	
								}
							}
						}
						else
							throw new Error("Error parsing catalog file.");
					}
					else
						resource.fields = null;

					// Validate relationship property
					if ((resource.relations instanceof Array)
							&& resource.relations[0]
							&& resource.relations[0].RelationName) {
						throw new Error(
								"Relationship properties in catalog must begin with lowercase.");
					}
					// Process operations
					resource.generic = {};
					if (resource.operations) {
						for (var idx=0;idx<resource.operations.length;idx++){
							if (resource.operations[idx].path) {
								resource.operations[idx].url = resource.url + resource.operations[idx].path;
							}
							else {
								resource.operations[idx].url = resource.url;
							}
                            if (!resource.operations[idx].params) {
                                resource.operations[idx].params = [];
                            }							
							if (!resource.operations[idx].type) {
								resource.operations[idx].type = "INVOKE";
							}
							
							// Set opname - validation of opname is done later
							var opname = resource.operations[idx].type.toLowerCase();							
							
							// Set default verb based on operation
							if (!resource.operations[idx].verb) {							
								switch (opname) {
								case 'create':
									resource.operations[idx].verb = "POST";
									break;									
								case 'read':
									resource.operations[idx].verb = "GET";
									break;																		
								case 'update':
								case 'invoke':									
									resource.operations[idx].verb = "PUT";
									break;																		
								case 'delete':
									resource.operations[idx].verb = "DELETE";
									break;
								default:
									break;
								}
							}							

							// Point fn to operations
                            var func = function fn(object, async) {
                                // Add static variable fnName to function
                                if (typeof fn.fnName == 'undefined') {
                                    fn.fnName = arguments[0]; // Name of function
                                    fn.definition = arguments[1]; // Operation definition
                                    return;
                                }
								var reqBody = null;
                                var url = fn.definition.url;
								var jsdo = this;
								var xhr = null;

								var request = {};
								if (object) {
									if (typeof(object) != "object") {
										throw new Error("Catalog error: Function '" + fn.fnName + "' requires an object as a parameter.");
									}
									var objParam;
									if (object instanceof XMLHttpRequest) {
										jsdo = object.jsdo;
										xhr = object;
										objParam = xhr.objParam;
										
										// use the request from the xhr request if possible
										request = xhr.request;
									}
									else {
										objParam = object;
									}
									
									if (typeof async == 'undefined') {
										async = this._async;
									}
									else {
										async = Boolean(async);
									}
									
									request.objParam = objParam;

									// Process objParam
									for (var i=0;i<fn.definition.params.length;i++) {
										var name = fn.definition.params[i].name;
										switch (fn.definition.params[i].type) {
										case 'PATH':
										case 'QUERY':
										case 'MATRIX':
											var value = null;
											if (objParam)
 												value = objParam[name];
											if (!value)
												value = "";
											url = url.replace(
													new RegExp('{' + name + '}', 'g'), 
														encodeURIComponent(value));
											break;
										case 'REQUEST_BODY':
											if (xhr && !reqBody) {
												reqBody = objParam;
											}
											else {
												if (!reqBody) {
													reqBody = {};
												}
												reqBody[name] = objParam[name];
											}
											break;
										case 'RESPONSE_BODY':
											break;
										default:
											throw new Error("Catalog error: Unexpected parameter type '" + fn.definition.params[i].type + "'");
										}
									}
									
									// URL has parameters
									if (url.indexOf('{') != -1) {
										var paramsFromURL = extractParamsFromURL(url);
										for (var i=0; i<paramsFromURL.length;i++) {
											var name = paramsFromURL[i];
											var value = null;
											if (objParam)
												value = objParam[name];
											if (!value)
												value = "";
											url = url.replace(
												new RegExp('{' + name + '}', 'g'), 
													encodeURIComponent(value));
										}
									}
								}
								
								request.fnName = fn.fnName;
								request.async = async;

                                var data = jsdo._httpRequest(xhr, fn.definition.verb, url, reqBody, request, async);
                                return data;
                            };
                            // End of Function Definition

							switch(resource.operations[idx].verb.toLowerCase()) {
							case 'get':
							case 'post':
							case 'put':
							case 'delete':
								break;
							default:
								throw new Error("Catalog error: Unexpected HTTP verb '" + resource.operations[idx].verb + "' found while parsing the catalog.");
							}

							switch (opname) {
							case 'invoke':
								break;
							case 'create':
							case 'read':
							case 'update':
							case 'delete':
								if (typeof(resource.generic[opname]) == "function") {
									throw new Error("Catalog error: Multiple '" + resource.operations[idx].type + "' operations specified in the catalog for resource '" + resource.name + "'.");
								}
								else
									resource.generic[opname] = func;
								break;
							default:
								throw new Error("Catalog error: Unexpected operation '" + resource.operations[idx].type + "' found while parsing the catalog.");
							}

                            // Set fnName
							var name = resource.operations[idx].name;
							if (opname == "invoke") {
								resource.fn[name] = {};
								resource.fn[name]["function"] = func;								
							}
							else {
								name = "_" + opname;
							}							
							func(name, resource.operations[idx]);							
						}
					}
				}
			}
		}
	}
	else {
		throw new Error("Missing 'services' array in catalog");
	}

};

/*
 * Prints debug information about the ServicesManager. 
 */
progress.data.ServicesManager.printDebugInfo = function(resourceName) {
	if (resourceName) {
		//console.log("** ServicesManager **");
		//console.log("** BEGIN **");
		var resource = progress.data.ServicesManager.getResource(resourceName);
		if (resource) {
			var cSchema = "Schema:\n";
			var cOperations = "Operations: " + resource.operations.length + "\n";
			for (var field in resource.schema.properties) {
				cSchema += "\nName: " + field
					+	"\n";
			}	

			for (var i=0; i < resource.operations.length; i++) {
				cOperations += "\n" + i
					+	"\nName: " + resource.operations[i].name
					+	"\nURL: " + resource.operations[i].url
					+	"\ntype: " + resource.operations[i].type
					+	"\nverb: " + resource.operations[i].verb
					+	"\nparams: " + resource.operations[i].params.length
					+ 	"\n"; 
			}
			console.log("** DEBUG INFO **\nResource name: %s\nURL:%s\n%s\n%s\n\n",
				resource.name, resource.url, cSchema, cOperations);
		}
		else
			console.log("Resource not found");
		//console.log("** END **");
	}
};

/*
 * Manages authentication and session ID information for a service.
 * 
 * Use:  OE mobile developer instantiates a session and calls addCatalog() to load
 *       information for one or more services defined in a catalog file.
 *       
 *       Developer instantiates JDSOs as needed.
 *       Usually all of the JSDOs will use the same session, but if a client-side
 *       service needs resources from more than one REST app, there would need to be more
 *       than one session 
 * 
 */
progress.data.Session = function Session( ) {

	var defPropSupported = false;
	if ((typeof Object.defineProperty) == 'function') {
		defPropSupported = true;
	}

	/* constants and properties - define them as properties via the defineProperty()
	 * function, which has "writable" and "configurable" parameters that both 
	 * default to false, so these calls create properties that are read-only
	 * 
	 * IF WE DECIDE THAT WE CAN ASSUME WE ALWAYS RUN WITH A VERSION OF JAVASCRIPT THAT SUPPORTS
	 * Object.DefineProperty(), WE CAN DELETE THE defPropSupported VARIABLE, THE TEST OF IT BELOW,
	 * AND THE 'ELSE' CLAUSE BELOW AND ALL THE setXxxx functions (AND CHANGE THE CALLS TO THE setXxxx 
	 * FUNCTIONS SO THEY JUST REFER TO THE PROPERTY)
	 * 
	 */
    
	// define these unconditionally so we don't get a warning on the push calls that they might
	// have been uninitialized
	var _catalogURIs = [];
	var _services = [];
    
    if (defPropSupported) {
	    Object.defineProperty( progress.data.Session, 'LOGIN_SUCCESS', { 
	    		                value: 1, enumerable: true }   );
	    Object.defineProperty( progress.data.Session, 'LOGIN_AUTHENTICATION_FAILURE', {
	        					value: 2, enumerable: true }  );
	    Object.defineProperty( progress.data.Session, 'LOGIN_GENERAL_FAILURE', {
	    						value:  3, enumerable: true });

	    Object.defineProperty( progress.data.Session, 'AUTH_TYPE_ANON', { 
            value: "anonymous", enumerable: true }   );
	    Object.defineProperty( progress.data.Session, 'AUTH_TYPE_BASIC', {
			value: "basic", enumerable: true }  );
	    Object.defineProperty( progress.data.Session, 'AUTH_TYPE_FORM', {
			value:  "form", enumerable: true });
	    
	    var _userName = null;
	    Object.defineProperty( this, 'userName', 
	    		               { get : function(){ return _userName; },
	    	                     enumerable: true } );
	    
	    var _loginTarget = '/static/home.html';
	    Object.defineProperty( this, 'loginTarget', 
	    		               { get : function(){ return _loginTarget; },
	    	                     enumerable: true } );
	    
	    var _serviceURI = null;
	    Object.defineProperty( this, 'serviceURI', 
	    		               { get : function(){ return _serviceURI; },
	    	                     enumerable: true } );

	    Object.defineProperty( this, 'catalogURIs', 
	               { get : function(){ return _catalogURIs; },
                  enumerable: true } );
  
	    Object.defineProperty( this, 'services', 
	               { get : function(){ return _services; },
                  enumerable: true } );

	    var _loginResult = null;
	    Object.defineProperty( this, 'loginResult', 
	               { get : function(){ return _loginResult; },
                     enumerable: true } );
	    
	    var _loginHttpStatus = null;
	    Object.defineProperty( this, 'loginHttpStatus', 
	               { get : function(){ return _loginHttpStatus; },
                     enumerable: true } );

	    var _clientContextId = null;
	    Object.defineProperty( this, 'clientContextId', 
	               { get : function(){ return _clientContextId; },
                     enumerable: true } );
	 
	    var _authenticationModel = progress.data.Session.AUTH_TYPE_ANON;
	    Object.defineProperty( this, 'authenticationModel', 
	               { get : function(){ return _authenticationModel; },
	    			 set : function( newval ) {
	    				 switch ( newval ) {
	    				 case progress.data.Session.AUTH_TYPE_FORM :
	    				 case progress.data.Session.AUTH_TYPE_BASIC :
	    				 case progress.data.Session.AUTH_TYPE_ANON :
	    				 case null :
	    					 _authenticationModel = newval ? newval.toLowerCase() : null;
	    					 break;
    					 default: 
	    					 throw new Error("Error setting Session.authenticationModel. '" + newval + "' is an invalid value.");
	    				 }
	    			 },
                     enumerable: true } );
	 
	}
	else {
		progress.data.Session.LOGIN_SUCCESS = 1;
		progress.data.Session.LOGIN_AUTHENTICATION_FAILURE = 2;
		progress.data.Session.LOGIN_GENERAL_FAILURE = 3;
		
		progress.data.Session.AUTH_TYPE_ANON = "anonymous";
		progress.data.Session.AUTH_TYPE_BASIC= "basic";
		progress.data.Session.AUTH_TYPE_FORM = "form";

		this.userName = null;
	    this.loginTarget= '/static/home.html';
	    this.serviceURI = null;
	    this.catalogURIs = [];
	    this.services = [];
	    this.loginResult = null;
	    this.loginHttpStatus = null; 
	    this.clientContextId = null; 
	    this.authenticationModel = progress.data.Session.AUTH_TYPE_ANON;
	}
	
	function setUserName(newname, sessionObject) {
		if (defPropSupported) { 
			_userName = newname;
		}
		else { 
			sessionObject.userName = newname;	
		}
	}

    function setLoginTarget(target, sessionObject) {
    	if (defPropSupported) { 
    		_loginTarget = target; 
    	}
    	else { 
    		sessionObject.loginTarget = target; 
    	};
    }

    function setServiceURI(url, sessionObject) {
    	if (defPropSupported) { 
    		_serviceURI = url; 
    	}
    	else { 
    		sessionObject.serviceURI = url; 
    	}
    }

    function pushCatalogURIs( url, sessionObject ) {
    	if (defPropSupported) { 
    		_catalogURIs.push(url); 
    	}
    	else { 
    		sessionObject.catalogURIs.push(url); 
    	}
    }

    function pushService( serviceNameAndURI, sessionObject ) {
    	if (defPropSupported) { 
    		_services.push( serviceNameAndURI ); 
    	}
    	else { 
    		sessionObject.services.push( serviceNameAndURI ); 
    	}
    }

    function setLoginResult( result, sessionObject ) {
    	if (defPropSupported) { 
    		_loginResult = result; 
    	}
    	else { 
    		sessionObject.loginResult = result; 
    	};
    }

    function setLoginHttpStatus( status, sessionObject ) {
    	if (defPropSupported) {
    		_loginHttpStatus = status; 
    	}
    	else { 
    		sessionObject.loginHttpStatus = status; 
    	}
    }

    function setClientContextIDfromXHR ( xhr, sessionObject ) {
    	if ( xhr ) {
    		setClientContextID( xhr.getResponseHeader( "X-CLIENT-CONTEXT-ID" ), sessionObject );
    	}
    };

    function setClientContextID ( ccid, sessionObject ) {
		if (defPropSupported) {
			_clientContextId = ccid;
		}
		else {
			sessionObject.clientContextId = ccid; 
		}
    };

    var _password = null;


    // "Methods"
    
    /* _openRequest  (intended for progress.data library use only)
     * calls open() for an xhr -- the assumption is that this is an xhr for a JSDO, and we need to add
     * some session management information for the request, such as user credentials and a session ID if
     * there is one
     */
	this._openRequest = function (xhr, verb, url, async) {

		// if resource url is not absolute, add the REST app url to the front
		var urlPlusCCID = this._prependAppURL( url );

		// add CCID as JSESSIONID query string to url
		urlPlusCCID = this._addCCIDtoURL( urlPlusCCID );
		
		xhr.open(verb, urlPlusCCID, async, this.userName, _password);
		
		// add CCID header
		if ( this.clientContextId && (this.clientContextId !== "0") ) {
			xhr.setRequestHeader( "X-CLIENT-CONTEXT-ID", this.clientContextId);
		}
		
		// do we need to set the withCredentials property to true, for CORS ?
	};

	/* login
	 *    
	 */
	this.login = function ( serviceURI, loginUserName, loginPassword, loginTarget ) {
		
		if ( arguments.length > 0) {
		    if ( arguments[0] ) {
		    	var restURLtemp = serviceURI;
		    	
		    	// get rid of trailing '/' because appending service url that starts with '/'
		    	// will cause request failures
		    	if ( restURLtemp[restURLtemp.length - 1] === "/") {
		    		restURLtemp = restURLtemp.substring(0, restURLtemp.length - 1);
		    	}
		    	setServiceURI( restURLtemp, this );
			}
			else {
			    setLoginResult(progress.data.Session.LOGIN_GENERAL_FAILURE, this);		    
				throw new Error( "Session.login() is missing the serviceURI argument" );		
			}
			
		    if ( arguments[1] ) {
		    	setUserName( arguments[1], this);
			}

		    if ( arguments[2]) {
				_password = arguments[2];
			}

		    if ( arguments[3]) {
				setLoginTarget(arguments[3], this);
			}
		}
		else {
		    setLoginResult(progress.data.Session.LOGIN_GENERAL_FAILURE, this);		    
			throw new Error( "Session.login() is missing the serviceURI argument" );		
		}

		var uname = this.userName;
		var pw = _password;
		if ( this.authenticationModel === progress.data.Session.AUTH_TYPE_ANON
			 || this.authenticationModel === progress.data.Session.AUTH_TYPE_FORM ) {
			/* anonymous should NOT have a username and password passed (this is 
			   probably unnecessary because the XHR seems to send the request without 
			   credentials first, then intercept the 401 if there is one and try again,
			   this time with credentials. Just making sure.
			*/
			/* For form authentication, we may as well not send the user name and password
			 * on this request, since we are just trying to test whether the authentication
			 *  has already happened and they are therefore irrelevant
			 */
			uname = null;
			pw = null;
		}
		
		var xhr = new XMLHttpRequest();

		xhr.open('GET', this.serviceURI + this.loginTarget, false, uname, pw);
		
		xhr.send(null);
		setLoginHttpStatus(xhr.status, this);
		
		if ( (this.authenticationModel === progress.data.Session.AUTH_TYPE_FORM)
			 && (this.loginHttpStatus == 200 || this.loginHttpStatus == 0) ) {
			// Check whether we didn't really have a successful authentication, just
			// were returned the login form
			if (_gotLoginForm(xhr) ) {
				/* Requested the login target, got success, but that was because the server
				 * returned the login form, which actually means authentication hasn't
				 * happened yet (if authentication has already happened, we would simply
				 * get success and the login target would have been returned).
				 * So -- use the credentials that were passed to login() to create a request that 
				 * looks like what Spring Security expects from the submit of the login form.
				 */
				xhr.open('POST', this.serviceURI + "/static/auth/j_spring_security_check", false);
				xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
				xhr.setRequestHeader("Cache-control", "max-age=0");
				xhr.setRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");

				// j_username=username&j_password=password&submit=Submit
				xhr.send("j_username=" + this.userName + "&j_password=" + _password + "&submit=Submit");

				if (xhr.status == 200 || xhr.status == 0) {
					// Was the response actually the login failure page or the login page itself (in case
					// the appSecurity config file sets the login failure url so the server sends the login 
					// page again)? If so, call it an error because the credentials apparently failed to be 
					// authenticated
					if (  _gotLoginFailure(xhr) || _gotLoginForm(xhr) ) {
						setLoginHttpStatus(401, this);						
					}
					else {
						setLoginHttpStatus(xhr.status, this);
					}
				}
			}
	    }
		
		if (this.loginHttpStatus == 200 || this.loginHttpStatus == 0) {
		    setLoginResult(progress.data.Session.LOGIN_SUCCESS, this);
		    
		    this._saveClientContextId( xhr );  
	    }
		else if (this.loginHttpStatus == 401) {
		    setLoginResult(progress.data.Session.LOGIN_AUTHENTICATION_FAILURE, this);
	    }
	    else {
		    setLoginResult(progress.data.Session.LOGIN_GENERAL_FAILURE, this);		    
	    }

		return this.loginResult;
	};
		

	/* logout
	 *    
	 */
	this.logout = function () {
		var xhr = new XMLHttpRequest();
	
		try {
			if (this.authenticationModel === progress.data.Session.AUTH_TYPE_FORM) {
				xhr.open('GET', this.serviceURI + "/static/auth/j_spring_security_logout", false);
				xhr.setRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
				xhr.send();
				
				if ( xhr.status != 200 && xhr.status != 0) {
					throw new Error("Error logging out, HTTP status = " + xhr.status);
				}
			}
			else {
				// Basic or Anonymous -- try to invalidate whatever session ID may be in effect
				// by sending the server a request with incorrect credentials
				xhr.open('GET', this.serviceURI + this.loginTarget, false);
	
				// this makes header for Basic auth. Will it suffice for invalidating an Anonymous
				// "session", too? Is that even necessary?
				var auth = _make_basic_auth("121312121906", "");
				xhr.setRequestHeader('Authorization', auth);
				
				xhr.send(null);
				setLoginHttpStatus(xhr.status, this); 
			}
		}
		catch(e) {
			throw e;
		}
		finally {
			setLoginResult( null, this );
		    setLoginHttpStatus( null, this);
		    setClientContextID ( null, this );
		}	    
	};
	
	/* addCatalog
	 *    
	 */
	this.addCatalog = function ( catalogURL, catalogUserName, catalogPassword ) {
		
		if ( this.loginResult !== progress.data.Session.LOGIN_SUCCESS && this.authenticationModel ) {
			throw new Error("Attempted to call addCatalog when there is no active session.");
		} 
		
		if ( arguments.length > 0) {
			
			if ( typeof catalogURL != 'string' ) {
				throw new Error( "First argument to Session.addCatalog must be the URL of the catalog" );		
			}

			if ( arguments[1]) {
				if ( typeof catalogUserName != 'string' ) {
					throw new Error( "Second argument to Session.addCatalog must be a user name string" );		
				}
			}
			else {
				catalogUserName = this.userName;
			}

			if ( arguments[2]) {
				if ( typeof catalogPassword != 'string' ){
					throw new Error( "Third argument to Session.addCatalog must be a password string" );		
				}
			}
			else {
				catalogPassword = _password;
			}
			
			// for now we don't support multiple version of the catalog across sessions
			if (progress.data.ServicesManager.getSession(catalogURL) != undefined)
				throw new Error ("Cannot load catalog '" + catalogURL + "' multiple times.");
		}
		else {
			throw new Error( "Session.addCatalog is missing its first argument, the URL of the catalog" );		
		}
		
		/* should we check whether catalog already loaded? */
		var xhr = new XMLHttpRequest();

		// Note that we are not adding the CCID to the URL or as a header, because the catalog may not
		// be stored with the REST app and even if it is, the AppServer ID shouldn't be relevant
		xhr.open('GET', catalogURL, false, catalogUserName, catalogPassword);

		xhr.send(null);
		var _catalogHttpStatus = xhr.status;
		
        if ((_catalogHttpStatus == 200) || (_catalogHttpStatus == 0)) {
    		var _servicedata = this._parseCatalog( xhr );
    		var serviceURL;
			if (!_servicedata) {
				throw new Error( "No services in catalog file: " + catalogURL );
			}
			progress.data.ServicesManager.addCatalog( _servicedata, this );

			// add service names to the storage for our property
			for (var i = 0; i < _servicedata.length; i++ ) {
				serviceURL = this._prependAppURL( _servicedata[i].address );
				pushService( { name : _servicedata[i].name,
								uri : serviceURL },
							 this);
			}
			pushCatalogURIs( catalogURL, this );
			progress.data.ServicesManager.addSession(catalogURL, this);

	    }
        else if (_catalogHttpStatus == 401) {
			throw new Error( "Authentication failed for catalog: " + catalogURL );
		    /*		
		    add logic to handle authentication failures ?? -- 
				determine where to get the username and password		
				xhr.open('GET', this._URL, async, this.username, this.password);		
			if ((typeof xhr.onAuthenticationErrorFn) == 'function')
				xhr.onAuthenticationErrorFn(this);
    		 */
	    }
	    else {
			throw new Error( "Unable to load catalog: " + catalogURL );
	    }
		
	};

	
    // "protected" Functions
    
    /*   _addCCIDtoURL  (intended for progress.data library use only)
     *  Add the Client Context ID being used by a session on an OE REST application, if we have
	 *	previously stored one from a response from the server
     */
    this._addCCIDtoURL = function ( url ) {
		if ( this.clientContextId && (this.clientContextId !== "0") ) {
			// TODO: ** Test protocol, host and port in addition to path to ensure that jsessionid is only sent
			// when request applies to the REST app (it might not be if the catalog is somewhere else)
			if ( url.substring(0, this.serviceURI.length) == this.serviceURI ) {
				var jsessionidStr = "JSESSIONID=" + this.clientContextId + ";";
				var index = url.indexOf('?');
				if (index == -1) {
					url += "?" + jsessionidStr;
				}
				else {
					url = url.substring(0, index + 1) + jsessionidStr + url.substring(index + 1);
				}
			}
		}
		return url;
    };
    
    /*   _saveClientContextId  (intended for progress.data library use only)
     *  If the CCID hasn't been set for the session yet, check the xhr for it and store it.
     *  (If it has been set, assume that the existing one is correct and do nothing. We could
     *   enhance this function by checking to see whether the new one matches the existing one.
     *  Not sure what to do if that's the case -- overwrite the old one? ignore the new one?
     *   Should at least log a warning or error
     */
    this._saveClientContextId = function( xhr ) {
    	// do this unconditionally (even if there is already a client-context-id), because
    	// if basic authentication is set up such that it uses sessions, and cookies are disabled,
    	// the server will generate a different session on each request and the X-CLIENT-CONTEXT-ID
    	// will therefore be different
    	setClientContextIDfromXHR( xhr, this );  
    };

	this._parseCatalog= function ( xhr ) {
		var jsonObject;
		var catalogdata;
		
		try {
			jsonObject = JSON.parse(xhr.responseText);
			catalogdata = jsonObject.services;
		}
		catch(e) {
			console.error( "Unable to parse response. Make sure catalog has correct format." );
			catalogdata = null;
		}

		return catalogdata;
	};

    /* _prependAppURL
     * Prepends the URL of the Web application (the 1st parameter passed to login, stored in this.serviceURI)
     * to whatever string is passed in. If the string passed in is an absolute URL, this function does
     * nothing except return a copy. This function ensures that the resulting URL has the correct number
     * of slashes between the web app url and the string passed in (currently that means that if what's
     * passed in has no initial slash, the function adds one)
     */
    this._prependAppURL = function( oldURL ) {
    	if ( !oldURL ) {
    		/* If oldURL is null, just return the app URL. (It's not the responsibility of this
    		 * function to decide whether having a null URL is an error. Its only responsibility
    		 * is to prepend the App URL to whatever it gets passed (and make sure the result is a valid URL)
    		 */
    		return this.serviceURI;
    	}
    	var newURL = oldURL;
		var pat = /^https?:\/\//i;
		if ( !pat.test(newURL) ) {
			if (newURL.indexOf("/") !== 0) {
				newURL = "/" + newURL; 
			}
			
			newURL = this.serviceURI + newURL;
		}
    	return newURL;
    };
    
	
	// Functions 
    // from http://coderseye.com/2007/how-to-do-http-basic-auth-in-ajax.html 
    function _make_basic_auth(user, pw) {
    	  var tok = user + ':' + pw;
//    	  var hash = base64_encode(tok);
    	  var hash = btoa(tok);
    	  return "Basic " + hash;
    }
    
    /* The next 2 functions, _gotLoginForm() and _gotLoginFailure(), attempt to determine whether 
     * a server response consists of
     * the application's login page or login failure page. Currently (release 11.2), this
     * is the only way we have of determining that a request made to the server that's
     * configured for form-based authentication failed due to authentication (i.e., 
     * authentication hadn't happened before the request and either invalid credentials or 
     * no credentials were sent to the server). That's because, due to the fact that the browser
     * or native wrapper typically intercepts the redirect involved in an unauthenticated request
     * to a server that's using using form auth, all we see in the XHR is a success status code
     * plus whatever page we were redirected to.   
     * In the future, we expect to enhance the OE REST adapter so that it will return a status code
     * indicating failure for form-based authentication, and we can reimplement these functions so
     * they check for that code rather than do the simplistic string search.  
     */  
    
	// Determines whether the content of the xhr is the login page. Assumes
    // use of a convention for testing for login page
    var loginFormIDString = "j_spring_security_check";
    function _gotLoginForm(xhr) {
		// is the response contained in an xhr actually the login page?
    	return _findStringInResponseHTML( xhr, loginFormIDString );
	}
  
	// Determines whether the content of the xhr is the login failure page. Assumes
    // use of a convention for testing for login fail page
    var loginFailureIdentificationString = "login failed";
    function _gotLoginFailure(xhr) {
    	return _findStringInResponseHTML( xhr, loginFailureIdentificationString );
	}

    // Does a given xhr contain html and does that html contain a given string?
    function _findStringInResponseHTML( xhr, searchString ) {
		if ( !xhr.responseText ) {
			return false;
		} 
		var contentType = xhr.getResponseHeader( "Content-Type" );

		if ( (contentType.indexOf("text/html") >= 0) &&
			 (xhr.responseText.indexOf(searchString) >= 0) ) {
			return true;
		}

		return false;						
    }
	
}; // End of Session

})();
