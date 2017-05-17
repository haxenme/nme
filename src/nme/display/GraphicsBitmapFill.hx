package nme.display;
#if (!flash)

import nme.geom.Matrix;
import nme.Loader;

@:nativeProperty
class GraphicsBitmapFill extends IGraphicsData 
{
   public function new(bitmapData:BitmapData = null, matrix:Matrix = null, repeat:Bool = true, smooth:Bool = false) 
   {
      super(nme_graphics_solid_fill_create(0, 1));
   }

   private static var nme_graphics_solid_fill_create = Loader.load("nme_graphics_solid_fill_create", 2);
}

#else
typedef GraphicsBitmapFill = flash.display.GraphicsBitmapFill;
#end
