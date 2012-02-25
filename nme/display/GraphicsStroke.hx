package nme.display;
#if (cpp || neko)


import nme.Loader;


class GraphicsStroke extends IGraphicsData
{	
	
	public function new(thickness:Null <Float> = null, pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle, ?joints:JointStyle, miterLimit:Float = 3, fill:IGraphicsData /* flash uses IGraphicsFill */ = null)
	{	
		super(nme_graphics_stroke_create(thickness, pixelHinting, scaleMode == null ? 0 : Type.enumIndex(scaleMode), caps == null ? 0 : Type.enumIndex(caps), joints == null ? 0 : Type.enumIndex(joints), miterLimit, fill == null ? null : fill.nmeHandle));	
	}
	
	
	private static var nme_graphics_stroke_create = Loader.load("nme_graphics_stroke_create", -1);
	
}


#elseif js

import nme.display.IGraphicsData;

class GraphicsStroke implements IGraphicsData, implements IGraphicsStroke
{
	public var caps : CapsStyle;
	public var fill : IGraphicsFill;
	public var joints : JointStyle;
	public var miterLimit : Float;
	public var pixelHinting : Bool;
	public var scaleMode : LineScaleMode;
	public var thickness : Float;
	public var jeashGraphicsDataType(default,null):GraphicsDataType;
	public function new(thickness : Float = 0., pixelHinting : Bool = false, ?scaleMode : LineScaleMode, ?caps : CapsStyle, ?joints : JointStyle, miterLimit : Float = 3, ?fill : IGraphicsFill) {
		this.caps = caps != null ? caps : null;
		this.fill = fill;
		this.joints = joints != null ? joints : null;
		this.miterLimit = miterLimit;
		this.pixelHinting = pixelHinting;
		this.scaleMode = scaleMode != null ? scaleMode : null;
		this.thickness = thickness;
		this.jeashGraphicsDataType = STROKE;
	}
}

#else
//typedef GraphicsStroke = flash.display.GraphicsStroke;
#end