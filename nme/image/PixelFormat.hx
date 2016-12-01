package nme.image;

class PixelFormat
{
   public inline static var pfNone       = -1;

   // 3 Bytes per pixel
   public inline static var pfRGB        = 0;
   // 0xAARRGGBB on little-endian = flash native format
   // This can generally be loaded right into the GPU (android simulator - maybe not)
   public inline static var pfBGRA       = 1;
   // Has the B,G,R components multiplied by A
   public inline static var pfBGRPremA   = 2;

   // 8-bit alpha
   public inline static var pfAlpha      = 3;

   // The first 4 pixel formats are supported as render sources/ render distinations
   public inline static var pfRenderToCount = 4;

   public inline static var pfLuma        = 4;
   public inline static var pfLumaAlpha   = 5;
   public inline static var pfRGB32f      = 6;
   public inline static var pfRGBA32f     = 7;

   // These formats are only used to transfer data to the GPU on systems that do
   //  not support the preferred pfBGRPremA format
   public inline static var pfRGBPremA   = 8;
   public inline static var pfRGBA       = 9;

   // These ones can't actually be displayed
   public inline static var pfUInt16      = 10;
   public inline static var pfUInt32      = 11;

}

