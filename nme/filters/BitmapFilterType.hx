package nme.filters;

#if (cpp || neko)

typedef BitmapFilterType = neash.filters.BitmapFilterType;

#elseif js

typedef BitmapFilterType = jeash.filters.BitmapFilterType;

#else

typedef BitmapFilterType = flash.filters.BitmapFilterType;

#end