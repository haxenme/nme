package nme.errors;
#if display


@:native("SecurityError") extern class SecurityError extends Error {
}


#elseif (cpp || neko)
typedef SecurityError = native.errors.SecurityError;
#elseif js
typedef SecurityError = browser.errors.SecurityError;
#else
typedef SecurityError = flash.errors.SecurityError;
#end
