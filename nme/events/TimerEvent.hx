package nme.events;

#if (cpp || neko)

typedef TimerEvent = neash.events.TimerEvent;

#elseif js

typedef TimerEvent = jeash.events.TimerEvent;

#else

typedef TimerEvent = flash.events.TimerEvent;

#end