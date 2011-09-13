package nme.display;
#if cpp || neko


class Sprite extends DisplayObjectContainer
{
   public function new()
	{
	   super(DisplayObjectContainer.nme_create_display_object_container(),nmeGetType());
	}

   public function startDrag(lockCenter:Bool = false, ?bounds:nme.geom.Rectangle):Void
	{
		if (stage!=null)
			stage.nmeStartDrag(this,lockCenter,bounds);
	}

	public function stopDrag() : Void
	{
		if (stage!=null)
			stage.nmeStopDrag(this);
	}
   function nmeGetType() { return "Sprite"; }
}


#else
typedef Sprite = flash.display.Sprite;
#end