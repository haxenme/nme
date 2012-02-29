package nme.events;

#if (cpp || neko)

typedef IOErrorEvent = neash.events.IOErrorEvent;

#elseif js

typedef IOErrorEvent = jeash.events.IOErrorEvent;

#else

typedef IOErrorEvent = flash.events.IOErrorEvent;

#end