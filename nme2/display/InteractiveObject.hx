package nme2.display;

class InteractiveObject extends DisplayObject
{

   function new(inHandle:Dynamic)
   {
      super(inHandle);
   }

	override function nmeAsInteractiveObject() : InteractiveObject { return this; }


}
