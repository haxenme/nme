package nme.filters;

#if (cpp || neko)

typedef BitmapFilterQuality = neash.filters.BitmapFilterQuality;

#elseif js

typedef BitmapFilterQuality = jeash.filters.BitmapFilterQuality;

#else

typedef BitmapFilterQuality = flash.filters.BitmapFilterQuality;

#end