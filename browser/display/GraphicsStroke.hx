package browser.display;
#if js


import browser.display.IGraphicsData;


class GraphicsStroke implements IGraphicsData implements IGraphicsStroke {
	
	
	public var caps:CapsStyle;
	public var fill:IGraphicsFill;
	public var joints:JointStyle;
	public var miterLimit:Float;
	public var nmeGraphicsDataType(default,null):GraphicsDataType;
	public var pixelHinting:Bool;
	public var scaleMode:LineScaleMode;
	public var thickness:Float;
	
	
	public function new(thickness:Float = 0.0, pixelHinting:Bool = false, scaleMode:LineScaleMode = null, caps:CapsStyle = null, joints:JointStyle = null, miterLimit:Float = 3, fill:IGraphicsFill = null) {
		
		this.caps = caps != null ? caps : null;
		this.fill = fill;
		this.joints = joints != null ? joints : null;
		this.miterLimit = miterLimit;
		this.pixelHinting = pixelHinting;
		this.scaleMode = scaleMode != null ? scaleMode : null;
		this.thickness = thickness;
		this.nmeGraphicsDataType = STROKE;
		
	}
	
	
}


#end