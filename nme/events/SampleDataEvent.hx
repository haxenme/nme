package nme.events;
#if (cpp || neko)

typedef SampleDataEvent = native.events.SampleDataEvent;

#else
typedef SampleDataEvent = flash.events.SampleDataEvent;
#end
