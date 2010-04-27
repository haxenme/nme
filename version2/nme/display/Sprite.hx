package nme.display;

class Sprite extends DisplayObjectContainer
{
   public function new()
	{
	   super(DisplayObjectContainer.nme_create_display_object_container());
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
}

