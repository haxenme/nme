package nme.utils;

#if (cpp || neko)

typedef Timer = neash.utils.Timer;

#elseif js

typedef Timer = jeash.utils.Timer;

#else

typedef Timer = flash.utils.Timer;

#end