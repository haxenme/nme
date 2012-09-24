package nme;

class RGB
{
   public static var ZERO = RGBA(0,0xff);
   public static var CLEAR = RGBA(0,0);
   public static var BLACK  = RGBA(0,0xff);
   public static var WHITE = RGBA(0xffffff,0xff);
   public static var RED = RGBA(0xff0000,0xff);
   public static var GREEN = RGBA(0x00ff00,0xff);
   public static var BLUE = RGBA(0x0000ff,0xff);
   public static var YELLOW = RGBA(0xffff00,0xff);

   public static function RGBA(inRGB:Int, inA:Int = 0xff)
   {
      #if neko
      return nme.display.BitmapData.createColor(inRGB,inA);
      #else
      return inRGB | (inA<<24);
      #end
   }

}


