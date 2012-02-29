package nme.events;

#if (cpp || neko)

typedef EventPhase = neash.events.EventPhase;

#elseif js

typedef EventPhase = jeash.events.EventPhase;

#else

typedef EventPhase = flash.events.EventPhase;

#end