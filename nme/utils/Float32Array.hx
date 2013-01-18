package nme.utils;


#if (cpp || neko)
typedef Float32Array = native.utils.Float32Array;
#elseif js
typedef Float32Array = browser.utils.Float32Array;
#end
