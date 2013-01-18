package nme.utils;


#if (cpp || neko)
typedef ArrayBufferView = native.utils.ArrayBufferView;
#elseif js
typedef ArrayBufferView = browser.utils.ArrayBufferView;
#end
