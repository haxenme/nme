package nme.display;
#if (!flash)

import nme.geom.Matrix;
import nme.Loader;

@:nativeProperty
class GraphicsGradientFill extends IGraphicsData 
{
   public function new(type:GradientType = null, colors:Array<Int> = null, alphas:Array<Float> = null, ratios:Array<Float> = null, matrix:Matrix = null, spreadMethod:SpreadMethod = null, interpolationMethod:InterpolationMethod = null, focalPointRatio:Float = 0):Void 
   {
      super(nme_graphics_solid_fill_create(0, 1));
   }

   private static var nme_graphics_solid_fill_create = Loader.load("nme_graphics_solid_fill_create", 2);
}

#else
typedef GraphicsGradientFill = flash.display.GraphicsGradientFill;
#end
