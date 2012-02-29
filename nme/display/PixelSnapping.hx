package nme.display;

#if (cpp || neko)

typedef PixelSnapping = neash.display.PixelSnapping;

#elseif js

typedef PixelSnapping = jeash.display.PixelSnapping;

#else

typedef PixelSnapping = flash.display.PixelSnapping;

#end