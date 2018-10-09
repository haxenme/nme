package nme.display;
#if (!flash)

enum PixelSnapping 
{
   NEVER;
   AUTO;
   ALWAYS;
}

#else
typedef PixelSnapping = flash.display.PixelSnapping;
#end
