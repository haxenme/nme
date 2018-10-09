package nme.display;

class FrameLabel extends nme.events.EventDispatcher
{
   public var frame:Int;
   public var name:String;

   public function new(inName:String, inFrame:Int)
   {
      super();
      name = inName;
      frame = inFrame;
   }
}

