package native.display;


import native.geom.Rectangle;


class Sprite extends DisplayObjectContainer {
	
	
	public var buttonMode:Bool; // ignored right now
	public var useHandCursor:Bool; // ignored right now
	
	
	public function new () {
		
		super (DisplayObjectContainer.nme_create_display_object_container (), nmeGetType ());
		
	}
	
	
	/** @private */ private function nmeGetType () {
		
		var type = Type.getClassName (Type.getClass (this));
		var pos = type.lastIndexOf (".");
		return pos >= 0 ? type.substr (pos + 1) : type;
		
	}
	
	
	public function startDrag (lockCenter:Bool = false, ?bounds:Rectangle):Void {
		
		if (stage != null)
			stage.nmeStartDrag (this, lockCenter, bounds);
		
	}
	
	
	public function stopDrag ():Void {
		
		if (stage != null)
			stage.nmeStopDrag (this);
		
	}
	
	
}