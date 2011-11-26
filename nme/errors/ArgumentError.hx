package nme.errors;
#if (cpp || neko)


class ArgumentError extends Error
{
}


#else
typedef ArgumentError = flash.errors.ArgumentError;
#end

