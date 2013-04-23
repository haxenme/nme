package nme.utils;


#if (cpp || neko)
typedef Int32Array = native.utils.Int32Array;
#elseif js
//typedef Int32Array = browser.utils.Int32Array;
#end
