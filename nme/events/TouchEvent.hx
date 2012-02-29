package nme.events;

#if (cpp || neko)

typedef TouchEvent = neash.events.TouchEvent;

#elseif js

typedef TouchEvent = jeash.events.TouchEvent;

#else

typedef TouchEvent = flash.events.TouchEvent;

#end