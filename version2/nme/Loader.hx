package nme;

class Loader
{
   public static function load(func:String, args:Int) : Dynamic
   {
   #if neko
      return neko.Lib.load("nme",func,args);
   #else
      return cpp.Lib.load("nme",func,args);
   #end
   }
}


