package nme.events;
#if display


/**
 * The EventPhase class provides values for the <code>eventPhase</code>
 * property of the Event class.
 */
@:fakeEnum(Int) extern enum EventPhase {
	AT_TARGET;
	BUBBLING_PHASE;
	CAPTURING_PHASE;
}


#elseif (cpp || neko)
typedef EventPhase = native.events.EventPhase;
#elseif js
typedef EventPhase = browser.events.EventPhase;
#else
typedef EventPhase = flash.events.EventPhase;
#end
