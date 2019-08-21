package nme.display;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class GraphicsStroke extends IGraphicsData 
{
   public function new(thickness:Float = -1, pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle, ?joints:JointStyle, miterLimit:Float = 3, fill:IGraphicsData /* flash uses IGraphicsFill */ = null) 
   {
      super(nme_graphics_stroke_create(thickness, pixelHinting, scaleMode == null ? 0 : Type.enumIndex(scaleMode), caps == null ? 0 : Type.enumIndex(caps), joints == null ? 0 : Type.enumIndex(joints), miterLimit, fill == null ? null : fill.nmeHandle));
   }

   private static var nme_graphics_stroke_create = PrimeLoader.load("nme_graphics_stroke_create", "dbiiidoo");
}

#else
typedef GraphicsStroke = flash.display.GraphicsStroke;
#end
