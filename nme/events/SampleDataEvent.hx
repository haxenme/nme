package nme.events;
#if (cpp || neko)

typedef SampleDataEvent = neash.events.SampleDataEvent;

#else
typedef SampleDataEvent = flash.events.SampleDataEvent;
#end
