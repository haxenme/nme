package nme;

class Loader
{
   public static function load(func:String, args:Int) : Dynamic
   {
   #if neko
      return neko.Lib.load("nme",func,args);
   #elseif cpp
      return cpp.Lib.load("nme",func,args);
   #elseif js
      return js.Lib.load("nme",func,args);
   #else
	   #error "unsupported platform";
   #end
   }
}


