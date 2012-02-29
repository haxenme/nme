package nme.events;

#if (cpp || neko)

typedef Event = neash.events.Event;

#elseif js

typedef Event = jeash.events.Event;

#else

typedef Event = flash.events.Event;

#end