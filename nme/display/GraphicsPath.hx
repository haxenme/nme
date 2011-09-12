package nme.display;


#if flash
@:native ("flash.display.GraphicsPath")
@:final extern class GraphicsPath implements IGraphicsData, implements IGraphicsPath {
	var commands : nme.Vector<Int>;
	var data : nme.Vector<Float>;
	var winding : GraphicsPathWinding;
	function new(?commands : nme.Vector<Int>, ?data : nme.Vector<Float>, ?winding : GraphicsPathWinding) : Void;
	function curveTo(controlX : Float, controlY : Float, anchorX : Float, anchorY : Float) : Void;
	function lineTo(x : Float, y : Float) : Void;
	function moveTo(x : Float, y : Float) : Void;
	function wideLineTo(x : Float, y : Float) : Void;
	function wideMoveTo(x : Float, y : Float) : Void;
}
#else



class GraphicsPath extends IGraphicsData
{
	public var commands(nmeGetCommands,nmeSetCommands):Array<Int>;
	public var data(nmeGetData,nmeSetData):Array<Float>;

	public function new(?commands:Array<Int>, ?data:Array<Float>,
	           winding:String = GraphicsPathWinding.EVEN_ODD )
	{
		super( nme_graphics_path_create(commands,data,winding==GraphicsPathWinding.EVEN_ODD) );
	}

	public function curveTo(controlX:Float, controlY:Float, anchorX:Float, anchorY:Float):Void
	{
		nme_graphics_path_curve_to(nmeHandle,controlX,controlY,anchorX,anchorY);
	}
	public function lineTo(x:Float, y:Float):Void
	{
		nme_graphics_path_line_to(nmeHandle,x,y);
	}
	public function moveTo(x:Float, y:Float):Void
	{
		nme_graphics_path_move_to(nmeHandle,x,y);
	}
	public function wideLineTo(x:Float, y:Float):Void
	{
		nme_graphics_path_wline_to(nmeHandle,x,y);
	}
	public function wideMoveTo(x:Float, y:Float):Void
	{
		nme_graphics_path_wmove_to(nmeHandle,x,y);
	}

	function nmeGetCommands() : Array<Int>
	{
	   var result = new Array<Int>();
		nme_graphics_path_get_commands(nmeHandle,result);
		return result;
	}

	function nmeSetCommands(inCommands:Array<Int>) : Array<Int>
	{
		nme_graphics_path_set_commands(nmeHandle,inCommands);
		return inCommands;
	}

	function nmeGetData() : Array<Float>
	{
	   var result = new Array<Float>();
		nme_graphics_path_get_data(nmeHandle,result);
		return result;
	}

	function nmeSetData(inData:Array<Float>) : Array<Float>
	{
		nme_graphics_path_set_data(nmeHandle,inData);
		return inData;
	}


   static var nme_graphics_path_create = nme.Loader.load("nme_graphics_path_create",3);
   static var nme_graphics_path_curve_to = nme.Loader.load("nme_graphics_path_curve_to",5);
   static var nme_graphics_path_line_to = nme.Loader.load("nme_graphics_path_line_to",3);
   static var nme_graphics_path_move_to = nme.Loader.load("nme_graphics_path_move_to",3);
   static var nme_graphics_path_wline_to = nme.Loader.load("nme_graphics_path_wline_to",3);
   static var nme_graphics_path_wmove_to = nme.Loader.load("nme_graphics_path_wmove_to",3);

   static var nme_graphics_path_get_commands = nme.Loader.load("nme_graphics_path_get_commands",2);
   static var nme_graphics_path_set_commands = nme.Loader.load("nme_graphics_path_set_commands",2);
   static var nme_graphics_path_get_data = nme.Loader.load("nme_graphics_path_get_data",2);
   static var nme_graphics_path_set_data = nme.Loader.load("nme_graphics_path_set_data",2);
}
#end