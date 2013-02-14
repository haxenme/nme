package browser.display;
#if js


import browser.display.IGraphicsData;
import browser.display.IGraphicsFill;
import browser.Html5Dom;


class GraphicsSolidFill implements IGraphicsData #if !haxe3 , #end implements IGraphicsFill {
	
	
	public var alpha:Float;
	public var color:UInt;
	public var nmeGraphicsDataType(default,null):GraphicsDataType;
	public var nmeGraphicsFillType(default,null):GraphicsFillType;
	
	
	public function new(color:UInt = 0, alpha:Float = 1) {
		
		this.alpha = alpha;
		this.color = color;
		this.nmeGraphicsDataType = SOLID;
		this.nmeGraphicsFillType = SOLID_FILL;
		
	}
	
	
}


#end