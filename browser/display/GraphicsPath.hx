package browser.display;
#if js


import browser.display.IGraphicsData;
import nme.Vector;


class GraphicsPath implements IGraphicsData #if !haxe3 , #end implements IGraphicsPath {
	
	
	public var commands:Vector<Int>;
	public var data:Vector<Float>;
	public var nmeGraphicsDataType(default, null):GraphicsDataType;
	public var winding:GraphicsPathWinding; /* note: currently ignored */
	
	
	public function new(commands:Vector<Int> = null, data:Vector<Float> = null, winding:GraphicsPathWinding = null) {
		
		this.commands = commands;
		this.data = data;
		this.winding = winding;
		this.nmeGraphicsDataType = PATH;
		
	}
	
	
	public function curveTo(controlX:Float, controlY:Float, anchorX:Float, anchorY:Float):Void {
		
		if (this.commands != null && this.data != null) {
			
			this.commands.push(GraphicsPathCommand.CURVE_TO);
			this.data.push(anchorX);
			this.data.push(anchorY);
			this.data.push(controlX);
			this.data.push(controlY);
			
		}
		
	}
	
	
	public function lineTo(x:Float, y:Float):Void {
		
		if (this.commands != null && this.data != null) {
			
			this.commands.push(GraphicsPathCommand.LINE_TO);
			this.data.push(x);
			this.data.push(y);
			
		}
		
	}
	
	
	public function moveTo(x:Float, y:Float):Void {
		
		if (this.commands != null && this.data != null) {
			
			this.commands.push(GraphicsPathCommand.MOVE_TO);
			this.data.push(x);
			this.data.push(y);
			
		}
		
	}
	
	
	//function wideLineTo(x : Float, y : Float) : Void;
	//function wideMoveTo(x : Float, y : Float) : Void;
	
	
}


#end