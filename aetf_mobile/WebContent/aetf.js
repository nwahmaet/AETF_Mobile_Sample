/**
*Copyright 2013 Progress Software Corporation
*
*Licensed under the Apache License, Version 2.0 (the "License");
*you may not use this file except in compliance with the License.
*You may obtain a copy of the License at
*
*  http://www.apache.org/licenses/LICENSE-2.0
*
*Unless required by applicable law or agreed to in writing, software
*distributed under the License is distributed on an "AS IS" BASIS,
*WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*See the License for the specific language governing permissions and
*limitations under the License.
**/
// General Mobile App & JavaScript code for AutoEdge|TheFactory
(function() {
  // 'namespaces'
  AETF = {};
  AETF.util = {};
  AETF.context = {};

  // private vars here

  // functions
  AETF.context.loginComplete = function(usrContext) {
    var ctx = JSON.parse(usrContext);
    if (!ctx.error) {          
      if (ctx.UserType === 'Customer') {
          localStorage.setItem('custNum', ctx.CustNum);
      };
      AETF.context.userContext = ctx;
    } else {
    	AETF.context.logoutComplete();
    };
  };

  AETF.context.logoutComplete = function() {
      if (AETF.context.userContext.UserType === 'Customer') {
          localStorage.removeItem('custNum');
      };

      AETF.context.userContext = null;
  };

  AETF.context.initSession = function(applicationURL, userName, password, catalogURL) {
    /* if the first time, or not logged in, try to log in */
    if (AETF.context.sessions == undefined
        || AETF.context.sessions[applicationURL] == undefined
        || AETF.context.sessions[applicationURL].loginResult != progress.data.Session.LOGIN_SUCCESS) {

      if (applicationURL == undefined || applicationURL == '')
        console.log("applicationURL was not specified. catalogURL: " + catalogURL);

      // putting the session object into our AETF namespace so that it can be
      // accessed later, if needed
      if (AETF.context.sessions == undefined) {AETF.context.sessions = {};};

      if (AETF.context.sessions[applicationURL] == undefined) {
        AETF.context.sessions[applicationURL] = new progress.data.Session();
      };

      var pdsession = AETF.context.sessions[applicationURL];
      var loginResult = pdsession.login(applicationURL, userName, password);

      if (loginResult != progress.data.Session.LOGIN_SUCCESS) {
        var msg;
        console.log('ERROR: Login failed with code: ' + loginResult);
        switch (loginResult) {
        case progress.data.Session.LOGIN_AUTHENTICATION_FAILURE:
          msg = 'Invalid userid or password';
          break;
        case progress.data.Session.LOGIN_GENERAL_FAILURE:
        default:
          msg = 'Service is unavailable';
          break;
        };

        /*
         * Optionally handle the login failure – the code depends on your
         * application design
         */
        alert(msg);
        /*
         * this would prevent a click of a button (i.e. login) from continuing,
         * for instance
         */
        return false;
      }
      // load catalog
      pdsession.addCatalog(catalogURL);
    };
  };

  /**
   * Returns GUID for new record keys
   */
  AETF.util.guid = function() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  };

  AETF.util.nextChar = function(c) {
    return String.fromCharCode(c.charCodeAt(0) + 1);
  };

  AETF.util.ucFirstLetter = function(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  };

})();
