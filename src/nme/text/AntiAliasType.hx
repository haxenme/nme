package nme.text;
#if (!flash)

enum abstract AntiAliasType(Int) from Int to Int
{
   var NORMAL = 0;
   var ADVANCED = 1;
   var ADVANCED_LCD = 2;
}

#else
typedef AntiAliasType = flash.text.AntiAliasType;
#end
