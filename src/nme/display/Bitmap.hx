package nme.display;
#if (!flash)

import nme.display.DisplayObject;
import nme.display.PixelSnapping;

@:nativeProperty
class Bitmap extends DisplayObject 
{
   public var bitmapData(default, set):BitmapData;
   public var smoothing(default, set):Bool;

   private var mGraphics:Graphics;

   public function new(bitmapData:BitmapData = null, pixelSnapping:PixelSnapping = null, smoothing:Bool = false):Void 
   {
      super(DisplayObject.nme_create_display_object(), "Bitmap");

      this.pixelSnapping = pixelSnapping == null ? PixelSnapping.AUTO : pixelSnapping;
      this.smoothing = smoothing;

      if (bitmapData != null) 
      {
         this.bitmapData = bitmapData;

      } else if (this.bitmapData != null) 
      {
         nmeRebuild();
      }
   }

   private function nmeRebuild() 
   {
      if (nmeHandle != null) 
      {
         var gfx = graphics;
         gfx.clear();

         if (bitmapData != null) 
         {
            gfx.beginBitmapFill(bitmapData, false, smoothing);
            gfx.drawRect(0, 0, bitmapData.width, bitmapData.height);
            gfx.endFill();
         }
      }
   }

   // Getters & Setters
   private function set_bitmapData(inBitmapData:BitmapData):BitmapData 
   {
      bitmapData = inBitmapData;
      nmeRebuild();

      return inBitmapData;
   }

   private function set_smoothing(inSmooth:Bool):Bool 
   {
      smoothing = inSmooth;
      nmeRebuild();

      return inSmooth;
   }
}

#else
typedef Bitmap = flash.display.Bitmap;
#end
