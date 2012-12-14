package native.display;


import native.Loader;


class GraphicsPath extends IGraphicsData {
	
	
	public var commands (get_commands, set_commands):Array<Int>;
	public var data (get_data, set_data):Array<Float>;
	
	
	public function new (?commands:Array<Int>, ?data:Array<Float>, winding:String = GraphicsPathWinding.EVEN_ODD) {
		
		super (nme_graphics_path_create (commands, data, winding == GraphicsPathWinding.EVEN_ODD));
		
	}
	
	
	public function curveTo (controlX:Float, controlY:Float, anchorX:Float, anchorY:Float):Void {
		
		nme_graphics_path_curve_to (nmeHandle, controlX, controlY, anchorX, anchorY);
		
	}
	
	
	public function lineTo (x:Float, y:Float):Void {
		
		nme_graphics_path_line_to (nmeHandle, x, y);
		
	}
	
	
	public function moveTo (x:Float, y:Float):Void {
		
		nme_graphics_path_move_to (nmeHandle, x, y);
		
	}
	
	
	public function wideLineTo (x:Float, y:Float):Void {
		
		nme_graphics_path_wline_to (nmeHandle, x, y);
		
	}
	
	
	public function wideMoveTo (x:Float, y:Float):Void {
		
		nme_graphics_path_wmove_to (nmeHandle, x, y);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_commands ():Array<Int> {
		
		var result = new Array<Int> ();
		nme_graphics_path_get_commands (nmeHandle, result);
		return result;
		
	}
	
	
	private function set_commands (inCommands:Array<Int>):Array<Int> {
		
		nme_graphics_path_set_commands (nmeHandle, inCommands);
		return inCommands;
		
	}
	
	
	private function get_data ():Array<Float> {
		
		var result = new Array<Float> ();		
		nme_graphics_path_get_data (nmeHandle, result);
		return result;
		
	}
	
	
	private function set_data (inData:Array<Float>):Array<Float> {
		
		nme_graphics_path_set_data (nmeHandle, inData);	
		return inData;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_graphics_path_create = Loader.load ("nme_graphics_path_create", 3);
	private static var nme_graphics_path_curve_to = Loader.load ("nme_graphics_path_curve_to", 5);
	private static var nme_graphics_path_line_to = Loader.load ("nme_graphics_path_line_to", 3);
	private static var nme_graphics_path_move_to = Loader.load ("nme_graphics_path_move_to", 3);
	private static var nme_graphics_path_wline_to = Loader.load ("nme_graphics_path_wline_to", 3);
	private static var nme_graphics_path_wmove_to = Loader.load ("nme_graphics_path_wmove_to", 3);
	private static var nme_graphics_path_get_commands = Loader.load ("nme_graphics_path_get_commands", 2);
	private static var nme_graphics_path_set_commands = Loader.load ("nme_graphics_path_set_commands", 2);
	private static var nme_graphics_path_get_data = Loader.load ("nme_graphics_path_get_data", 2);
	private static var nme_graphics_path_set_data = Loader.load ("nme_graphics_path_set_data", 2);
	
	
}