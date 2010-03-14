package nme.media;

class SoundChannel extends nme.events.EventDispatcher
{
   public var leftPeak(nmeSoundChannelGetLeft,null) : Float;
   public var rightPeak(nmeSoundChannelGetRight,null) : Float;
   public var position(nmeSoundChannelGetPosition,null) : Float;
   public var soundTransform(nmeSoundChannelGetTransform,nmeSoundChannelSetTransform) : SoundTransform;

   var nmeHandle:Dynamic;
   public function new(inHandle:Dynamic)
   {
      nmeHandle = inHandle;
      super();
   }

}
