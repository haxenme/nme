package nme.utils;


#if (cpp || neko)
typedef ArrayBuffer = native.utils.ArrayBuffer;
#elseif js
typedef ArrayBuffer = browser.utils.ArrayBuffer;
#end
