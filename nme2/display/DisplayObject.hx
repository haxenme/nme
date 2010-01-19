package nme2.display;

class DisplayObject
{
	public var graphics(nmeGetGraphics,null) : nme2.display.Graphics;
   var nmeHandle:Dynamic;

   public function new(inHandle:Dynamic)
	{
		nmeHandle = inHandle;
	}

	public function nmeGetGraphics() : nme2.display.Graphics
	{
	   return new nme2.display.Graphics( nme_display_object_get_grapics(nmeHandle) );
	}


	static var nme_create_display_object = nme2.Loader.load("nme_create_display_object",0);
	static var nme_display_object_get_grapics = nme2.Loader.load("nme_display_object_get_graphics",1);
}
