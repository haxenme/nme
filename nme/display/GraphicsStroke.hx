package nme.display;


#if flash
@:native ("flash.display.GraphicsStroke")
@:final extern class GraphicsStroke implements IGraphicsData, implements IGraphicsStroke {
	var caps : CapsStyle;
	var fill : IGraphicsFill;
	var joints : JointStyle;
	var miterLimit : Float;
	var pixelHinting : Bool;
	var scaleMode : LineScaleMode;
	var thickness : Float;
	function new(thickness : Float = 0./*NaN*/, pixelHinting : Bool = false, ?scaleMode : String, ?caps : String, ?joints : String, miterLimit : Float = 3, ?fill : IGraphicsFill) : Void;
}
#else



class GraphicsStroke extends IGraphicsData, implements IGraphicsStroke
{

   public function new(thickness:Null<Float>=null, pixelHinting:Bool = false,
	                   ?scaleMode:LineScaleMode, ?caps:CapsStyle,
                      ?joints:JointStyle, miterLimit:Float = 3,
                      fill:IGraphicsData /* flash uses IGraphicsFill */  = null)
	{
	   super( nme_graphics_stroke_create(thickness, pixelHinting,
         scaleMode==null ?  0 : Type.enumIndex(scaleMode),
         caps==null ?  0 : Type.enumIndex(caps),
         joints==null ?  0 : Type.enumIndex(joints),
         miterLimit, fill==null ? null : fill.nmeHandle  ) );
	}

   static var nme_graphics_stroke_create = nme.Loader.load("nme_graphics_stroke_create",-1);
}
#end