package neash.display;

import neash.Loader;
import nme.events.Event;

class DirectRenderer extends DisplayObject
{

   public function new(inType:String = "DirectRenderer")
   {
     super(nme_direct_renderer_create(),inType);
     addEventListener(Event.ADDED_TO_STAGE,function(_) nme_direct_renderer_set(nmeHandle,nmeOnRender) );
     addEventListener(Event.REMOVED_FROM_STAGE,function(_) nme_direct_renderer_set(nmeHandle,null) );
   }

   public dynamic function render( )
   {
   }

   function nmeOnRender()
   {
      render();
   }

	private static var nme_direct_renderer_create = Loader.load("nme_direct_renderer_create", 0);
	private static var nme_direct_renderer_set = Loader.load("nme_direct_renderer_set", 2);
}

