package nme.events;

#if (cpp || neko)

typedef FocusEvent = neash.events.FocusEvent;

#elseif js

typedef FocusEvent = jeash.events.FocusEvent;

#else

typedef FocusEvent = flash.events.FocusEvent;

#end