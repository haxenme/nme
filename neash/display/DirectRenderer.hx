package neash.display;

import neash.Loader;
import nme.events.Event;

typedef RenderInfo =
{
   rect : { x:Float, y:Float, width:Float, height:Float },
   matrix : { a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float },
}

class DirectRenderer extends DisplayObject
{

   public function new(inType:String = "DirectRenderer")
   {
     super(nme_direct_renderer_create(),inType);
     addEventListener(Event.ADDED_TO_STAGE,function(_) nme_direct_renderer_set(nmeHandle,nmeOnRender) );
     addEventListener(Event.REMOVED_FROM_STAGE,function(_) nme_direct_renderer_set(nmeHandle,null) );
   }

   public dynamic function render(inInfo:RenderInfo)
   {
   }

   function nmeOnRender(inInfo:RenderInfo)
   {
      if (render!=null)
         render(inInfo);
   }

	private static var nme_direct_renderer_create = Loader.load("nme_direct_renderer_create", 0);
	private static var nme_direct_renderer_set = Loader.load("nme_direct_renderer_set", 2);
}

