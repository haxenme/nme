package;

import NMEProject;

class StringMapHelper 
{
   public static function copy <T>(source:haxe.ds.StringMap<T>):haxe.ds.StringMap<T> 
   {
      var target = new haxe.ds.StringMap<T>();

      for(key in source.keys()) 
      {
         target.set(key, source.get(key));
      }

      return target;
   }

   public static function copyKeys <T>(source:haxe.ds.StringMap<T>, target:haxe.ds.StringMap<T>):Void 
   {
      for(key in source.keys()) 
      {
         target.set(key, source.get(key));
      }
   }

   public static function copyUniqueKeys <T>(source:haxe.ds.StringMap<T>, target:haxe.ds.StringMap<T>):Void 
   {
      for(key in source.keys()) 
      {
         if (!target.exists(key)) 
         {
            target.set(key, source.get(key));
         }
      }
   }
}
