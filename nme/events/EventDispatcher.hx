package nme.events;

#if (cpp || neko)

typedef EventDispatcher = neash.events.EventDispatcher;

#elseif js

typedef EventDispatcher = jeash.events.EventDispatcher;

#else

typedef EventDispatcher = flash.events.EventDispatcher;

#end