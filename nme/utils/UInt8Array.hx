package nme.utils;


#if (cpp || neko)
typedef UInt8Array = native.utils.UInt8Array;
#elseif js
typedef UInt8Array = browser.utils.UInt8Array;
#end
