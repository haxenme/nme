package;


import sys.FileSystem;


class NDLL {
	
	
	public var haxelib:String;
	public var name:String;
	public var path:String;
	
	
	public function new (name:String, haxelib:String = "") {
		
		this.name = name;
		this.haxelib = haxelib;
		
	}
	
	
	public function clone ():NDLL {
		
		var ndll = new NDLL (name, haxelib);
		ndll.path = path;
		return ndll;
		
	}
	
	
}