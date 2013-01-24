package nme.utils;


#if (cpp || neko)
typedef Int16Array = native.utils.Int16Array;
#elseif js
typedef Int16Array = browser.utils.Int16Array;
#end
