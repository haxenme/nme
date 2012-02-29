package common;

#if !flash
import nme.events.MouseEvent;
import nme.display.InteractiveObject;
import nme.display.Sprite;
import nme.display.DisplayObject;
import nme.geom.Rectangle;
#else
import flash.events.MouseEvent;
import flash.display.InteractiveObject;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.geom.Rectangle;
#end


class Scrollbar extends Sprite
{
   var mThumbHeight:Float;
   var mPage:Float;
   var mHeight:Float;
   var mRange:Float;
   var mThumb:Sprite;
   var mRemoveFrom:DisplayObject;

   public function new(inWidth:Float, inHeight:Float, inRange:Float, inPage:Float)
   {
      super();
      var gfx = graphics;
      gfx.lineStyle(1,0x404040);
      gfx.beginFill(0xeeeeee);
      gfx.drawRect(0,0,inWidth,inHeight);

      mThumbHeight = inHeight * inPage / inRange;
      mRange = inRange;
      mHeight = inHeight;
      mPage = inPage;
      var thumb = new Sprite();
      var gfx = thumb.graphics;
      gfx.lineStyle(1,0x000000);
      gfx.beginFill(0xffffff);
      gfx.drawRect(0,0,inWidth,mThumbHeight);
      addChild(thumb);
      mThumb = thumb;

      thumb.addEventListener( MouseEvent.MOUSE_DOWN, thumbStart );
   }

   dynamic public function scrolled(inTo:Float)
   {
   }

   function onScroll(e:MouseEvent)
   {
      var denom = mHeight-mThumbHeight;
      if (denom>0)
      {
         var ratio = mThumb.y/denom;
         scrolled(ratio*mRange);
      }
   }

   function thumbStart(e:MouseEvent)
   {
      mRemoveFrom = stage;
      mThumb.addEventListener( MouseEvent.MOUSE_UP, thumbStop );
      mRemoveFrom.addEventListener( MouseEvent.MOUSE_UP, thumbStop );
      mRemoveFrom.addEventListener( MouseEvent.MOUSE_MOVE, onScroll );
      mThumb.startDrag(false, new Rectangle(0,0,0,mHeight-mThumbHeight));
   }
   function thumbStop(e:MouseEvent)
   {
      mThumb.stopDrag();
      mThumb.removeEventListener( MouseEvent.MOUSE_UP, thumbStop );
      mRemoveFrom.removeEventListener( MouseEvent.MOUSE_UP, thumbStop );
      mRemoveFrom.removeEventListener( MouseEvent.MOUSE_MOVE, onScroll );
   }
}



