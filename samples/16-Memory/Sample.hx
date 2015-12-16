import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.Assets;
import nme.Memory;

class Sample extends Sprite
{
   var mDisplay:Bitmap;
   var mBitmap:BitmapData;
   var cachedPixels:nme.utils.ByteArray;

   function new()
   {
      super();

      mBitmap = Assets.getBitmapData("image1.jpg");

      mDisplay = new Bitmap(mBitmap);
      addChild(mDisplay);

      stage.addEventListener(flash.events.Event.ENTER_FRAME, updateBitmap);
      stage.addEventListener(flash.events.Event.RESIZE, function(_) updateScale);
      updateScale();
   }

   function updateScale()
   {
     if (stage!=null)
     {
        var sx = stage.stageWidth / mBitmap.width;
        var sy = stage.stageHeight / mBitmap.height;
        mDisplay.scaleX = mDisplay.scaleY= Math.min(sx,sy);
     }
   }

   static var pass = 0;
   static var demo = 1;
   function updateBitmap(_)
   {
      if (demo==0)
      {
         gameOfLifeInts();
      }
      else
         cycleColours();

      pass++;
      #if (neko || cppia)
      if (pass==40)
      #else
      if (pass==500)
      #end
      {
         pass = 0;
         demo = 1-demo;
         if (demo==0)
            mBitmap = Assets.getBitmapData("image2.png");
         else
            mBitmap = Assets.getBitmapData("image1.jpg");
         mDisplay.bitmapData = mBitmap;
         cachedPixels = null;
         updateScale();
      }

   }

   function cycleColours()
   {
      var w = mBitmap.width;
      var h = mBitmap.height;
      var r = new Rectangle(0,0,w,h);

      if (cachedPixels==null)
        cachedPixels = mBitmap.getPixels(r);
      var pixels = cachedPixels;

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


   static var tTot = 0.0;
   static var tCount = 0;
   function gameOfLifeByteArray()
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
 


   function gameOfLifeInts()
   {
      var w = mBitmap.width;
      var h = mBitmap.height;
      var r = new Rectangle(0,0,w,h);

      var pixels = mBitmap.getVector(r);

      // Create a combined array with destination at the bottom, and source at the
      //  top so with can so a single "select" call.
      var next = new nme.Vector<Int>();
      next[pixels.length-1] = 0;


      var t0 = haxe.Timer.stamp();
      var idx = 0;
      var w_ = w-1;
      var h_ = h-1;
      for(y in 0...h)
         for(x in 0...w)
         {
             var alive = (pixels[idx] & 0xff) < 128;
             var total = 0;

             // Unroll loop
             #if true
             if (y>0)
             {
                var idx0 = idx - w;
                if (x>0 && (pixels[ idx0 -1 ] & 0xff) < 128 )
                   total++;
                if ((pixels[ idx0 ] & 0xff) < 128 )
                   total++;
                if (x<w_ && (pixels[ idx0 +1 ] & 0xff) < 128 )
                   total++;
             }

             if (x>0 && (pixels[ idx - 1] & 0xff) < 128 )
                total++;
             if (x<w_ && (pixels[ idx +1 ] & 0xff) < 128 )
                total++;

             if (y<h_)
             {
                var idx0 = idx + w;
                if (x>0 && (pixels[ idx0 -1 ] & 0xff) < 128 )
                   total++;
                if ((pixels[ idx0 ] & 0xff) < 128 )
                   total++;
                if (x<w_ && (pixels[ idx0 +1 ] & 0xff) < 128 )
                   total++;
             }
             #else

             for(dy in -1...2)
                for(dx in -1...2)
                {
                   if (dx!=0 || dy!=0)
                   {
                      var tx = x+dx;
                      var ty = y+dy;
                      if (tx>=0 && ty>=0 && tx<w && ty<h &&
                            (pixels[ idx + (dy*w+dx) ] & 0xff) < 128 )
                         total++;
                   }
                }
             #end

             next[idx] = (alive && (total==2||total==3)) || ((!alive) && total==3)  ? 0xff000000 : 0xffffffff; 
             idx++;
         }
      mBitmap.setVector(r,next);
      var t = haxe.Timer.stamp()-t0;
      tTot += t;
      tCount ++;
      //trace("Time: " + t + " : " + (tTot/tCount));
   }
   

}

