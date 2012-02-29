package nme.events;

#if (cpp || neko)

typedef IEventDispatcher = neash.events.IEventDispatcher;

#elseif js

typedef IEventDispatcher = jeash.events.IEventDispatcher;

#else

typedef IEventDispatcher = flash.events.IEventDispatcher;

#end