package data;


class LaunchImage
{	
	public var name(default, null):String;
	private var width(default, null):Null<Int>;
	private var height(default, null):Null<Int>;
	
	public function new (name:String, width:String, height:String) {
		this.name = name;

		if (width == "") {
			this.width = null;
		} else {
			this.width = Std.parseInt(width);
		}
		
		if (height == "") {
			this.height = null;
		} else {
			this.height = Std.parseInt(height);
		}
	}
	
	public function isSize (width:Int, height:Int) {	
		return this.width == width && this.height == height;
	}
	
	public function matches (width:Int, height:Int) {
		return (this.width == width || this.width == null) && (this.height == height || this.height == null);
	}
}