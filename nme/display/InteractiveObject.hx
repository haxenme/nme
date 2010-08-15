package nme.display;

class InteractiveObject extends DisplayObject
{
   public var mouseEnabled(nmeGetMouseEnabled,nmeSetMouseEnabled):Bool;

	var nmeMouseEnabled:Bool;

   function new(inHandle:Dynamic)
   {
	   nmeMouseEnabled = true;
      super(inHandle);
   }

	function nmeGetMouseEnabled() : Bool { return nmeMouseEnabled; }
	function nmeSetMouseEnabled(inVal:Bool) : Bool
	{
	   nmeMouseEnabled = inVal;
		nme_display_object_set_mouse_enabled(nmeHandle, inVal);
	   return nmeMouseEnabled;
	}

	override function nmeAsInteractiveObject() : InteractiveObject { return this; }


   static var nme_display_object_set_mouse_enabled = nme.Loader.load("nme_display_object_set_mouse_enabled",2);
}
