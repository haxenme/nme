package nme.display;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class GraphicsEndFill extends IGraphicsData 
{
   public function new() 
   {
      super(nme_graphics_end_fill_create());
   }

   private static var nme_graphics_end_fill_create = PrimeLoader.load("nme_graphics_end_fill_create", "o");
}

#else
typedef GraphicsEndFill = flash.display.GraphicsEndFill;
#end
