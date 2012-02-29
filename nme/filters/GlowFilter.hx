package nme.filters;

#if (cpp || neko)

typedef GlowFilter = neash.filters.GlowFilter;

#elseif js

typedef GlowFilter = jeash.filters.GlowFilter;

#else

typedef GlowFilter = flash.filters.GlowFilter;

#end