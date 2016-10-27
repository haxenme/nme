import nme.utils.ByteArray;
import nme.utils.ByteArrayTools;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.geom.Matrix;
using cpp.NativeMath;

class Render extends Sprite
{
   static function createBmp(inAlpha:Bool,inPrem:Bool) : BitmapData
   {
      var bmp =
         #if (!flash)
         if (inPrem) BitmapData.createPremultiplied(16,16) else
         #end
         new BitmapData(16,16,inAlpha,0x000000);
      var pixels = ByteArrayTools.ofLength(256*4);
      var val = 1;
      var idx = 0;
      for(i in 0...16)
      {
         pixels[idx++] = 0xff;
         pixels[idx++] = 0x00;
         pixels[idx++] = 0x00;
         pixels[idx++] = inAlpha ? (i*255).idiv(15) : 255;
      }
      for(i in 0...16)
      {
         pixels[idx++] = 0x00;
         pixels[idx++] = 0xff;
         pixels[idx++] = 0x00;
         pixels[idx++] = inAlpha ? (i*255).idiv(15) : 255;
      }
      for(i in 0...16)
      {
         pixels[idx++] = 0x00;
         pixels[idx++] = 0x00;
         pixels[idx++] = 0xff;
         pixels[idx++] = inAlpha ? (i*255).idiv(15) : 255;
      }

      for(i in 0...(16-3)*16)
      {
         val = val*1103515245 + 12345;
         pixels[idx++] = val & 0xff;
         val = val*1103515245 + 12345;
         pixels[idx++] = val & 0xff;
         val = val*1103515245 + 12345;
         pixels[idx++] = val & 0xff;
         val = val*1103515245 + 12345;
         pixels[idx++] = (val & 0xff) | (inAlpha ? 0 : 255);
      }
      bmp.setPixels( new Rectangle(0,0,16,16), pixels);
      return bmp;
   }

   static function createBmp90(inAlpha:Bool,inPrem:Bool) : BitmapData
   {
      var bmp = new BitmapData(16,16,inAlpha,0x000000);
      var src = createBmp(inAlpha,inPrem);
      var matrix = new Matrix(0,1,1,0, 0,0);
      bmp.draw( new Bitmap(src), matrix);
      return bmp;
   }


   public function new()
   {
      super();
      var dpiScale = nme.system.Capabilities.screenDPI/96;
      if (dpiScale<1.5)
          dpiScale = 1.0;
      scaleX = scaleY = 10*dpiScale;


      var bmp = createBmp(false,false);
      var bitmap = new Bitmap(bmp);
      addChild(bitmap);

      var bmp = createBmp90(true,false);
      var bitmap = new Bitmap(bmp);
      bitmap.x = 20;
      addChild(bitmap);
   }
}

