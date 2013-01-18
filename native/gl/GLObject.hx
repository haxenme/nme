package native.gl;
#if (cpp || neko)


class GLObject {
	
	
	public var id(default, null):Dynamic;
	public var invalidated(get_invalidated, null):Bool;
	public var valid(get_valid, null):Bool;
	
	private var version:Int;
	
	
	private function new(inVersion:Int, inId:Dynamic) {
		
		version = inVersion;
		id = inId;
		
	}
	
	
	private function getType():String {
		
		return "GLObject";
		
	}
	
	
	public function invalidate():Void {
		
		id = null;
		
	}
	
	
	public function isValid():Bool {
		
		return id != null && version == GL.version;
		
	}
	
	
	public function isInvalid():Bool {
		
		return !isValid();
		
	}
	
	
	public function toString():String {
		
		return getType() + "(" + id + ")";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_invalidated():Bool {
		
		return isInvalid();
		
	}
	
	
	private function get_valid():Bool {
		
		return isValid();
		
	}
	
	
}


#end