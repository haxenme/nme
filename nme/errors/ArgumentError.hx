package nme.errors;
#if (!flash)

class ArgumentError extends Error 
{
}

#else
typedef ArgumentError = flash.errors.ArgumentError;
#end
