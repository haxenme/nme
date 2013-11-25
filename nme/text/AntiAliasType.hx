package nme.text;
#if (cpp || neko)

enum AntiAliasType 
{
   ADVANCED;
   NORMAL;
}

#else
typedef AntiAliasType = flash.text.AntiAliasType;
#end