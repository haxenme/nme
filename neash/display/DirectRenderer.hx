package neash.display;

import neash.Loader;
import nme.events.Event;
import nme.geom.Rectangle;

class DirectRenderer extends DisplayObject
{

   public function new(inType:String = "DirectRenderer")
   {
     super(nme_direct_renderer_create(),inType);
     addEventListener(Event.ADDED_TO_STAGE,function(_) nme_direct_renderer_set(nmeHandle,nmeOnRender) );
     addEventListener(Event.REMOVED_FROM_STAGE,function(_) nme_direct_renderer_set(nmeHandle,null) );
   }

   public dynamic function render(inRect:Rectangle)
   {
   }

   function nmeOnRender(inRect:Dynamic)
   {
      if (render!=null)
         render(new Rectangle(inRect.x, inRect.y, inRect.width, inRect.height) );
   }

	private static var nme_direct_renderer_create = Loader.load("nme_direct_renderer_create", 0);
	private static var nme_direct_renderer_set = Loader.load("nme_direct_renderer_set", 2);
}

