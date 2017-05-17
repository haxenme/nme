package nme.errors;
#if (!flash)

class IllegalOperationError extends Error 
{
}

#else
typedef IllegalOperationError = flash.errors.IllegalOperationError;
#end
