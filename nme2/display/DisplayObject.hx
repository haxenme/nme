package nme2.display;
import nme2.events.Event;

class DisplayObject extends nme2.events.EventDispatcher
{
	public var graphics(nmeGetGraphics,null) : nme2.display.Graphics;
	public var x(nmeGetX,nmeSetX): Float;
	public var y(nmeGetY,nmeSetY): Float;

   var nmeHandle:Dynamic;
	var nmeParent:DisplayObjectContainer;
	var nmeName:String;
	var nmeID:Int;
	static var nmeNextID = 0;


   public function new(inHandle:Dynamic)
	{
		nmeParent = null;
		nmeHandle = inHandle;
		nmeName = "DisplayObject";
		nmeID = nmeNextID++;
	}
   public function toString() : String { return nmeName + " " + nmeID; }

	public function nmeGetGraphics() : nme2.display.Graphics
	{
	   return new nme2.display.Graphics( nme_display_object_get_grapics(nmeHandle) );
	}

	public function nmeGetX() : Float
	{
	   return nme_display_object_get_x(nmeHandle);
	}

	public function nmeSetX(inVal:Float) : Float
	{
	   nme_display_object_set_x(nmeHandle,inVal);
		return inVal;
	}

	public function nmeGetY() : Float
	{
	   return nme_display_object_get_y(nmeHandle);
	}

	public function nmeSetY(inVal:Float) : Float
	{
	   nme_display_object_set_y(nmeHandle,inVal);
		return inVal;
	}




	function nmeOnAdded(inObj:DisplayObject)
	{
		if (inObj==this)
		{
			var evt = new Event(Event.ADDED, true, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}

		var evt = new Event(Event.ADDED_TO_STAGE, false, false);
		evt.target = inObj;
		dispatchEvent(evt);
	}

	function nmeOnRemoved(inObj:DisplayObject)
	{
		if (inObj==this)
		{
			var evt = new Event(Event.REMOVED, true, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}
		var evt = new Event(Event.REMOVED_FROM_STAGE, false, false);
		evt.target = inObj;
		dispatchEvent(evt);
	}

	public function nmeSetParent(inParent:DisplayObjectContainer)
	{
		if (inParent == nmeParent)
			return;

		if (nmeParent != null)
			nmeParent.nmeRemoveChildFromArray(this);

		if (nmeParent==null && inParent!=null)
		{
			nmeParent = inParent;
			nmeOnAdded(this);
		}
		else if (nmeParent!=null && inParent==null)
		{
			nmeParent = inParent;
			nmeOnRemoved(this);
		}
		else
			nmeParent = inParent;
	}


	static var nme_create_display_object = nme2.Loader.load("nme_create_display_object",0);
	static var nme_display_object_get_grapics = nme2.Loader.load("nme_display_object_get_graphics",1);
	static var nme_display_object_get_x = nme2.Loader.load("nme_display_object_get_x",1);
	static var nme_display_object_set_x = nme2.Loader.load("nme_display_object_set_x",2);
	static var nme_display_object_get_y = nme2.Loader.load("nme_display_object_get_y",1);
	static var nme_display_object_set_y = nme2.Loader.load("nme_display_object_set_y",2);
}
