package nme.filters;

#if (cpp || neko)

typedef BlurFilter = neash.filters.BlurFilter;

#elseif js

typedef BlurFilter = jeash.filters.BlurFilter;

#else

typedef BlurFilter = flash.filters.BlurFilter;

#end