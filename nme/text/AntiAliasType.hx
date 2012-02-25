package nme.text;
#if (cpp || neko || js)


enum AntiAliasType
{
   ADVANCED;
   NORMAL;
}


#else
typedef AntiAliasType = flash.text.AntiAliasType;
#end