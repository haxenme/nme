package nme.display;


#if flash
@:native ("flash.display.Shape")
extern class Shape extends DisplayObject {
	var graphics(default,null) : Graphics;
	function new() : Void;
}
#else



class Shape extends DisplayObject
{
   public function new()
	{
	   super(DisplayObject.nme_create_display_object(), "Shape");
	}
}
#end