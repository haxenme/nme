package nme.events;

#if (!flash)

@:nativeProperty
class StatusEvent extends Event
{
   public static inline var STATUS = "status";
   public static inline var WARNING = "warning";
   public static inline var ERROR = "error";

  

   public var code : String;
   public var level : String;

   public function new(type : String, bubbles:Bool=false, cancelable:Bool=false, inCode:String="", inLevel:String="")
   {
      super(type,bubbles,cancelable);
      code = inCode;
      level = inLevel;
   }
}


#else
typedef NetStatusEvent = flash.events.NetStatusEvent;
#end


