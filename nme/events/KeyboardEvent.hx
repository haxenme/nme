package nme.events;

#if (cpp || neko)

typedef KeyboardEvent = neash.events.KeyboardEvent;

#elseif js

typedef KeyboardEvent = jeash.events.KeyboardEvent;

#else

typedef KeyboardEvent = flash.events.KeyboardEvent;

#end