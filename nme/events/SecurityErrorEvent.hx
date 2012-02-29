package nme.events;

#if (cpp || neko)

typedef SecurityErrorEvent = neash.events.SecurityErrorEvent;

#elseif js

typedef SecurityErrorEvent = jeash.events.SecurityErrorEvent;

#else

typedef SecurityErrorEvent = flash.events.SecurityErrorEvent;

#end