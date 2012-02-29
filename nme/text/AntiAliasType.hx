package nme.text;

#if (cpp || neko)

typedef AntiAliasType = neash.text.AntiAliasType;

#elseif js

typedef AntiAliasType = jeash.text.AntiAliasType;

#else

typedef AntiAliasType = flash.text.AntiAliasType;

#end