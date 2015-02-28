package nme.events;

@:nativeProperty
class StageVideoAvailabilityEvent extends Event
{
   public var availability(default,null) : String;
   public static inline var STAGE_VIDEO_AVAILABILITY = "stageVideoAvailability";

   public function new(type : String, bubbles : Bool = false, cancelable : Bool = false, ?inAvailability : String) : Void
   {
      super(type,bubbles,cancelable);
      availability = inAvailability;
   }
}
