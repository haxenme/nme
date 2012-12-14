package native.display;


import native.Loader;


class GraphicsStroke extends IGraphicsData {
	
	
	public function new (thickness:Null < Float > = null, pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle, ?joints:JointStyle, miterLimit:Float = 3, fill:IGraphicsData /* flash uses IGraphicsFill */ = null) {
		
		super (nme_graphics_stroke_create (thickness, pixelHinting, scaleMode == null ? 0 : Type.enumIndex (scaleMode), caps == null ? 0 : Type.enumIndex (caps), joints == null ? 0 : Type.enumIndex (joints), miterLimit, fill == null ? null : fill.nmeHandle));
		
	}
	
	
	private static var nme_graphics_stroke_create = Loader.load ("nme_graphics_stroke_create", -1);
	
	
}