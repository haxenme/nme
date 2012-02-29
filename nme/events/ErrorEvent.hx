package nme.events;

#if (cpp || neko)

typedef ErrorEvent = neash.events.ErrorEvent;

#elseif js

typedef ErrorEvent = jeash.events.ErrorEvent;

#else

typedef ErrorEvent = flash.events.ErrorEvent;

#end