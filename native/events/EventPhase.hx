package native.events;
#if (cpp || neko)

class EventPhase 
{
   public static var CAPTURING_PHASE = 0;
   public static var AT_TARGET = 1;
   public static var BUBBLING_PHASE = 2;
}

#end