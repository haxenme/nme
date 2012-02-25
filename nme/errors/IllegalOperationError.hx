package nme.errors;
#if (cpp || neko || js)


class IllegalOperationError extends Error
{
}


#else
typedef IllegalOperationError = flash.errors.IllegalOperationError;
#end

