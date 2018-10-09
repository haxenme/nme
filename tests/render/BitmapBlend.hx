import nme.utils.ByteArray;
import nme.utils.ByteArrayTools;
import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.BlendMode;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.geom.Matrix;
using cpp.NativeMath;

class BitmapBlend extends TestBase
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
      scaleX = scaleY = 4;

      blendMode = LAYER;

      name = "BitmapBlend";
      var gfx = graphics;
      gfx.beginFill(0x777777);
      gfx.drawRect(0,0,800,600);

      var bmp = createBmp(false,false);
      var bitmap = new Bitmap(bmp);
      addChild(bitmap);
      label("Normal",0,16);

      var bmp = createBmp90(true,false);
      var bitmap = new Bitmap(bmp);
      bitmap.x = 20;
      addChild(bitmap);
      label("Rot 90",20,16);

      var y = 20;

      for(prem in 0...2)
      {
         var x = 0;
         for(mode in [ ADD, SCREEN, MULTIPLY, LIGHTEN, DARKEN, DIFFERENCE, SUBTRACT,
                       OVERLAY, HARDLIGHT, INVERT, ALPHA, ERASE ])
         {
            var bmp = createBmp(true,prem>0);
            var bitmap = new Bitmap(bmp);
            bitmap.y = y;
            bitmap.x = x*20;
            bitmap.blendMode = mode;
            addChild(bitmap);
            label(Std.string(mode),x*20,y+16);
            x++;
            if (x>8)
            {
               x = 0;
               y+= 30;
            }

         }
         y+=30;
      }

      resize();
   }

}

