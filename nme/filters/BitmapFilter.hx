package nme.filters;

#if (cpp || neko)

typedef BitmapFilter = neash.filters.BitmapFilter;

#elseif js

typedef BitmapFilter = jeash.filters.BitmapFilter;

#else

typedef BitmapFilter = flash.filters.BitmapFilter;

#end