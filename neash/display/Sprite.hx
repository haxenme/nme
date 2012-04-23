package neash.display;
#if (cpp || neko)


import neash.geom.Rectangle;


class Sprite extends DisplayObjectContainer
{
	
	
	// ignored right now
	public var buttonMode:Bool;
	public var useHandCursor:Bool;
	
	
	public function new()
	{
		super(DisplayObjectContainer.nme_create_display_object_container(), nmeGetType());
	}
	
	
	/** @private */ private function nmeGetType()
	{
      var type = Type.getClassName(Type.getClass(this));
      var pos = type.lastIndexOf(".");
      return pos>=0 ? type.substr(pos+1) : type;
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
