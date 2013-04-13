import nme.Lib;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.display.DisplayObject;
import nme.display.IGraphicsData;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.GradientType;
import nme.display.Sprite;
import nme.display.StageDisplayState;
import nme.geom.Matrix;
import nme.ui.Multitouch;

class Sample extends Sprite
{
   var colourHash:IntHash<Int>;
   var mBitmap:BitmapData;
   var mMultiTouch:Bool;
   
   public function new()
   {
      super();
      Lib.current.addChild(this);

      mMultiTouch = nme.ui.Multitouch.supportsTouchEvents;
      if (mMultiTouch)
         nme.ui.Multitouch.inputMode = nme.ui.MultitouchInputMode.TOUCH_POINT;
      trace("Using multi-touch : " + mMultiTouch);
      mBitmap = new BitmapData(320,480);
      addChild(new Bitmap(mBitmap));
      colourHash = new IntHash<Int>();
   
      var me = this;
      var cols = [ 0xff0000, 0x00ff00, 0x0000ff ];
      var gfx = graphics;

      for(i in 0...3)
      {
         var pot = new Sprite();
         var gfx = pot.graphics;
         gfx.beginFill( cols[i] );
         gfx.drawCircle( 40+80*i, 40, 25 );
         addChild(pot);

         if (mMultiTouch)
            pot.addEventListener(nme.events.TouchEvent.TOUCH_BEGIN, 
                function(e) { me.OnDown(e,cols[i]); } );
         else
            pot.addEventListener(nme.events.MouseEvent.MOUSE_DOWN, 
                function(e) { me.OnDown(e,cols[i]); } );
      gfx.drawRoundRect(10,100,40,30,10,10);
      }

      if (mMultiTouch)
      {
         stage.addEventListener(nme.events.TouchEvent.TOUCH_MOVE, OnMove);
         stage.addEventListener(nme.events.TouchEvent.TOUCH_END, OnUp);
      }
      else
      {
         stage.addEventListener(nme.events.MouseEvent.MOUSE_MOVE, OnMove);
         stage.addEventListener(nme.events.MouseEvent.MOUSE_UP, OnUp);
      }
   }
   
   function OnDown(event,pot)
   {
      colourHash.set(mMultiTouch ? event.touchPointID : 0, pot);
   }
   
   function OnMove(event)
   {
      var id = mMultiTouch ? event.touchPointID : 0;
      if (colourHash.exists(id))
      {
         var col = colourHash.get(mMultiTouch ? event.touchPointID : 0);
         var cx = Std.int(event.localX);
         var cy = Std.int(event.localY);
         trace("ID : " + id + " " + cx + "," + cy + " = " + col);
         for(x in cx-2 ... cx+3)
            for(y in cy-2 ... cy+3)
               if (x>=0 && y>=0 && x<mBitmap.width && y<mBitmap.height)
                  mBitmap.setPixel(x,y,col);
      }
   }
   
   function OnUp(event)
   {
      colourHash.remove(mMultiTouch ? event.touchPointID : 0);
   }
   
   public static function main()
   {
      new Sample();
   }
   
}
