package nme.events;

#if (cpp || neko)

typedef MouseEvent = neash.events.MouseEvent;

#elseif js

typedef MouseEvent = jeash.events.MouseEvent;

#else

typedef MouseEvent = flash.events.MouseEvent;

#end