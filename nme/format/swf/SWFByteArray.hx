package nme.format.swf;

#if flash

typedef SWFByteArray = flash.utils.ByteArray;

#else true

typedef SWFByteArray = String;

#end
