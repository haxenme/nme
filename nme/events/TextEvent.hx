package nme.events;

#if (cpp || neko)

typedef TextEvent = neash.events.TextEvent;

#elseif js

typedef TextEvent = jeash.events.TextEvent;

#else

typedef TextEvent = flash.events.TextEvent;

#end