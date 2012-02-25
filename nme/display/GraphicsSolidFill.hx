package nme.display;
#if (cpp || neko)


import nme.Loader;


class GraphicsSolidFill extends IGraphicsData
{	
	
	public function new(color:Int = 0, alpha:Float = 1.0)
	{	
		super(nme_graphics_solid_fill_create(color, alpha));
	}
	
	
	private static var nme_graphics_solid_fill_create = Loader.load("nme_graphics_solid_fill_create", 2);
	
}


#elseif js

import nme.display.IGraphicsData;
import nme.display.IGraphicsFill;
import Html5Dom;

class GraphicsSolidFill implements IGraphicsData, implements IGraphicsFill 
{
	public var alpha : Float;
	public var color : UInt;
	public var jeashGraphicsDataType(default,null):GraphicsDataType;
	public var jeashGraphicsFillType(default,null):GraphicsFillType;
	public function new(color : UInt = 0, alpha : Float = 1) {
		this.alpha = alpha;
		this.color = color;
		this.jeashGraphicsDataType = SOLID;
		this.jeashGraphicsFillType = SOLID_FILL;
	}
}

#else
//typedef GraphicsSolidFill = flash.display.GraphicsSolidFill;
#end