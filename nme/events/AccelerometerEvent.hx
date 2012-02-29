package nme.events;

#if (cpp || neko)

typedef AccelerometerEvent = neash.events.AccelerometerEvent;

#elseif js

typedef AccelerometerEvent = jeash.events.AccelerometerEvent;

#else

typedef AccelerometerEvent = flash.events.AccelerometerEvent;

#end