package nme.utils;

#if (cpp || neko)

typedef IDataInput = neash.utils.IDataInput;

#elseif js

typedef IDataInput = jeash.utils.IDataInput;

#else

typedef IDataInput = flash.utils.IDataInput;

#end