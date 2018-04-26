let EXPORTED_SYMBOLS = ['getCmdLineArg'];

function CommandLineObserver(argName, cb) {
  this._argName = argName;
  this._cb = cb;
  this.register();
}
CommandLineObserver.prototype = {
  observe: function(aSubject, aTopic, aData) {
    var cmdLine = aSubject.QueryInterface(Components.interfaces.nsICommandLine);
    var argValue = cmdLine.handleFlagWithParam(this._argName, false);
    if (this._cb)
      this._cb(argValue);

    // We only want the value once
    this.unregister();
  },

  register: function() {
    var observerService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(Components.interfaces.nsIObserverService);
    observerService.addObserver(this, "commandline-args-changed", false);
  },

  unregister: function() {
    var observerService = Components.classes["@mozilla.org/observer-service;1"]
                                    .getService(Components.interfaces.nsIObserverService);
    observerService.removeObserver(this, "commandline-args-changed");
  }
}

function getCmdLineArg (window, argName, cb) {
  var observer = new CommandLineObserver(argName, cb);

  // Trigger the observer by simulating a notification
  var observerService = Components.classes["@mozilla.org/observer-service;1"]
                                   .getService(Components.interfaces.nsIObserverService);
  observerService.notifyObservers(window.arguments[0], "commandline-args-changed", null);
}
