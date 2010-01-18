package nme2;

class Loader
{
   public static function load(func:String, args:Int) : Dynamic
   {
   #if neko
      return neko.Lib.load("nme2",func,args);
   #else
      return cpp.Lib.load("nme2",func,args);
   #end
   }
}


