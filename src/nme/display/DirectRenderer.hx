package nme.display;
#if (!flash)

import nme.Loader;
import nme.events.Event;
import nme.geom.Rectangle;

@:nativeProperty
class DirectRenderer extends DisplayObject 
{
   public function new(inType:String = "DirectRenderer") 
   {
      super(nme_direct_renderer_create(), inType);

      addEventListener(Event.ADDED_TO_STAGE, function(_) nme_direct_renderer_set(nmeHandle, nmeOnRender));
      addEventListener(Event.REMOVED_FROM_STAGE, function(_) nme_direct_renderer_set(nmeHandle, null));
   }

   private function nmeOnRender(inRect:Dynamic) 
   {
      if (render != null) render(new Rectangle(inRect.x, inRect.y, inRect.width, inRect.height));
   }

   public dynamic function render(inRect:Rectangle) 
   {
   }

   // Native Methods
   private static var nme_direct_renderer_create = Loader.load("nme_direct_renderer_create", 0);
   private static var nme_direct_renderer_set = Loader.load("nme_direct_renderer_set", 2);
}

#end
