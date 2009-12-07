var EXPORTED_SYMBOLS = ["JSJaC"];

/**
 * @fileoverview Magic dependency loading. Taken from script.aculo.us
 * and modified to break it.
 * @author Stefan Strigler steve@zeank.in-berlin.de
 * @version $Revision$
 */

var JSJaC = {
  Version: '$Rev$',
  require: function(libraryName) {
    // inserting via DOM fails in Safari 2.0, so brute force approach
    document.write('<script type="text/javascript" src="'+libraryName+'"></script>');
  },
  load: function() {
    var includes =
    ['xmlextras',
     'jsextras',
     'crypt',
     'JSJaCConfig',
     'JSJaCConstants',
     'JSJaCCookie',
     'JSJaCJSON',
     'JSJaCJID',
     'JSJaCBuilder',
     'JSJaCPacket',
     'JSJaCError',
     'JSJaCKeys',
     'JSJaCConnection',
     'JSJaCHttpPollingConnection',
     'JSJaCHttpBindingConnection',
     'JSJaCConsoleLogger'
     ];
    var scripts = document.getElementsByTagName("script");
    var path = './';
    for (var i=0; i<scripts.length; i++) {
      if (scripts.item(i).src && scripts.item(i).src.match(/JSJaC\.js$/)) {
        path = scripts.item(i).src.replace(/JSJaC.js$/,'');
        break;
      }
    }
    for (var i=0; i<includes.length; i++)
      this.require(path+includes[i]+'.js');
  },
  bind: function(fn, obj, arg) {
    return function() {
      if (arg)
        fn.apply(obj, arg);
      else
        fn.apply(obj);
    };
  }
};

ML.importMod("3rdparty/jsjac/xmlextras.js");
ML.importMod("3rdparty/jsjac/jsextras.js");
ML.importMod("3rdparty/jsjac/crypt.js");
ML.importMod("3rdparty/jsjac/JSJaCConfig.js");
ML.importMod("3rdparty/jsjac/JSJaCConstants.js");
ML.importMod("3rdparty/jsjac/JSJaCCookie.js");
ML.importMod("3rdparty/jsjac/JSJaCJID.js");
ML.importMod("3rdparty/jsjac/JSJaCBuilder.js");
ML.importMod("3rdparty/jsjac/JSJaCPacket.js");
ML.importMod("3rdparty/jsjac/JSJaCError.js");
ML.importMod("3rdparty/jsjac/JSJaCKeys.js");
ML.importMod("3rdparty/jsjac/JSJaCConnection.js");
ML.importMod("3rdparty/jsjac/JSJaCMozillaConnection.js");
ML.importMod("3rdparty/jsjac/JSJaCConsoleLogger.js");
