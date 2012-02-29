package nme.events;

#if (cpp || neko)

typedef ProgressEvent = neash.events.ProgressEvent;

#elseif js

typedef ProgressEvent = jeash.events.ProgressEvent;

#else

typedef ProgressEvent = flash.events.ProgressEvent;

#end