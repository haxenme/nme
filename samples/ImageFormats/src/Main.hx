import nme.display.*;
import nme.image.PixelFormat;
import cpp.Pointer;

class Main extends Sprite
{
   public function new()
   {
      super();
      var bmp16 = BitmapData.createUInt16(400,300);

      var pixels = new Array<Int>();
      for(y in 0...300)
         for(x in 0...400)
            pixels.push( y*3 );
      bmp16.setData(pixels, PixelFormat.pfUInt32);

      var bytes = bmp16.getBytes();
      trace(bmp16 + " " + bmp16.format + "x" + bytes.length);

      var vals = new Array<cpp.UInt16>();
      vals[bmp16.width*bmp16.height-1] = 0;
      bmp16.getData(Pointer.ofArray(vals));
      trace("LastVal:", vals[400*300-1] );

      bmp16.save("png16.png");

      var recon = BitmapData.load("png16.png");
      trace(recon + " " + recon.format);

      var vals = new Array<cpp.UInt16>();
      vals[recon.width*recon.height-1] = 0;
      recon.getData(Pointer.ofArray(vals),PixelFormat.pfUInt16);

      for(v in 0...vals.length)
         if (vals[v]>255)
            vals[v] = 255;

      var bmp = new BitmapData(400,300,false,0xff00ffff);
      bmp.setData( Pointer.ofArray(vals), PixelFormat.pfUInt16 );

      addChild( new Bitmap(bmp) );
      trace("New bmp.." + bmp);
   }
}


