let EXPORTED_SYMBOLS = ['debugLog'];

function debugLog (msg) {
  var file = Components.classes['@mozilla.org/file/local;1']
                       .createInstance(Components.interfaces.nsILocalFile);
  file.initWithPath('/Users/adrien/my-console');
  var foStream = Components.classes['@mozilla.org/network/file-output-stream;1']
                           .createInstance(Components.interfaces.nsIFileOutputStream);
  // 0x02 - open for writing
  // 0x08 - create if not exists
  // 0x10 - append
  // 0x20 - truncate
  foStream.init(file, 0x02 | 0x08 | 0x10, 0666, 0);
  if (msg.slice(-1)[0] != '\n')
    foStream.write(msg + '\n', msg.length + 1);
  else
    foStream.write(msg, msg.length);
  foStream.close();
}
