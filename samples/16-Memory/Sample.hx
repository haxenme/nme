import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.Memory;

class Sample extends Sprite
{
   var mDisplay:Bitmap;
   var mBitmap:BitmapData;

   function new()
   {
      super();
      flash.Lib.current.addChild(this);

      mBitmap = ApplicationMain.getAsset("image1.jpg");

      mDisplay = new Bitmap(mBitmap);
      addChild(mDisplay);

      stage.addEventListener(flash.events.Event.ENTER_FRAME, updateBitmap);
   }

   static var pass = 0;
   static var demo = 1;
   function updateBitmap(_)
   {
      if (demo==0)
         gameOfLife();
      else
         cycleColours();

      pass++;
      if (pass==500)
      {
         pass = 0;
         demo = 1-demo;
         if (demo==0)
            mBitmap = ApplicationMain.getAsset("image2.png");
         else
            mBitmap = ApplicationMain.getAsset("image1.jpg");
         mDisplay.bitmapData = mBitmap;
      }
   }

   function cycleColours()
   {
      var w = mBitmap.width;
      var h = mBitmap.height;
      var r = new Rectangle(0,0,w,h);

      var pixels = mBitmap.getPixels(r);

      Memory.select(pixels);
      var idx = 0;
      for(p in 0...w*h)
      {
         idx++; // Skip alpha

         Memory.setByte( idx, Memory.getByte( idx ) + 8 ); idx++;
         Memory.setByte( idx, Memory.getByte( idx ) + 8 ); idx++;
         Memory.setByte( idx, Memory.getByte( idx ) + 8 ); idx++;
      }
      pixels.position = 0;
      mBitmap.setPixels(r,pixels);
      Memory.select(null);
   }


   function gameOfLife()
   {
      var w = mBitmap.width;
      var h = mBitmap.height;
      var r = new Rectangle(0,0,w,h);

      var pixels = mBitmap.getPixels(r);

      // Create a combined array with destination at the bottom, and source at the
      //  top so with can so a single "select" call.
      var image_size = w*h*4;
      var combined = new ByteArray();
      #if flash combined.length = image_size; #else combined.setLength(image_size); #end

      combined.position = image_size;
      combined.writeBytes(pixels);

      Memory.select(combined);

      var idx = 0;
      for(y in 0...h)
         for(x in 0...w)
         {
             Memory.setByte( idx++, 255 );
             for(col in 0...3)
             {
                var alive = Memory.getByte( image_size + idx ) < 128;
                var total = 0;
                for(dy in -1...2)
                   for(dx in -1...2)
                   {
                      if (dx!=0 || dy!=0)
                      {
                         var tx = x+dx;
                         var ty = y+dy;
                         if (tx>=0 && ty>=0 && tx<w && ty<h &&
                               Memory.getByte( image_size + idx + ((dy*w+dx)<<2) ) < 128 )
                            total++;
                      }
                   }

                Memory.setByte(idx, (alive && (total==2||total==3)) || ((!alive) && total==3)  ? 0:255); 
                idx++;
             }
         }

      Memory.select(null);

      combined.position = 0;
      mBitmap.setPixels(r,combined);
   }
   

   public static function main()
   {
      new Sample();
   }
}

