package nme.filters;

#if (cpp || neko)

typedef DropShadowFilter = neash.filters.DropShadowFilter;

#elseif js

typedef DropShadowFilter = jeash.filters.DropShadowFilter;

#else

typedef DropShadowFilter = flash.filters.DropShadowFilter;

#end