package nme.display;
#if (cpp || neko)


import nme.geom.Rectangle;


class Sprite extends DisplayObjectContainer
{
	
	public function new()
	{
		super(DisplayObjectContainer.nme_create_display_object_container(), nmeGetType());
	}
	
	
	private function nmeGetType()
	{
		return "Sprite";
	}
	
	
	public function startDrag(lockCenter:Bool = false, ?bounds:Rectangle):Void
	{
		if (stage != null)
			stage.nmeStartDrag(this, lockCenter, bounds);
	}
	
	
	public function stopDrag():Void
	{
		if (stage != null)
			stage.nmeStopDrag(this);
	}
	
}


#else
typedef Sprite = flash.display.Sprite;
#end