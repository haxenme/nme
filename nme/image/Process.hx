package nme.image;

import nme.native.ImageBuffer;
import nme.display.BitmapData;


@:generic
abstract Process<T>(T)
{
   public static inline function run(bitmap:BitmapData)
   {
      T.run<Rgb>(BitmapData);
   }
}
