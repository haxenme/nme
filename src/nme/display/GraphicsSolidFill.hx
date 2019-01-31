package nme.display;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class GraphicsSolidFill extends IGraphicsData 
{
   public function new(color:Int = 0, alpha:Float = 1.0) 
   {
      super(nme_graphics_solid_fill_create(color, alpha));
   }

   private static var nme_graphics_solid_fill_create = PrimeLoader.load("nme_graphics_solid_fill_create", "ido");
}

#else
typedef GraphicsSolidFill = flash.display.GraphicsSolidFill;
#end
