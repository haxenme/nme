package nme.errors;
#if (cpp || neko)


class IllegalOperationError extends Error
{
}


#else
typedef IllegalOperationError = flash.errors.IllegalOperationError;
#end

