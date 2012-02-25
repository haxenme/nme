package nme.errors;
#if (cpp || neko || js)


class ArgumentError extends Error
{
	
}


#else
typedef ArgumentError = flash.errors.ArgumentError;
#end