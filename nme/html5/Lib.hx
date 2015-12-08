package nme.html5;

class Lib
{
   static function merge(outResult:Dynamic, clazz:Class<Dynamic>)
   {
      for(field in Type.getClassFields(clazz))
         Reflect.setField(outResult,field,Reflect.field(clazz,field) );
   }

   public static function init()
   {
      var functions = {};

      merge(functions,App);

      return functions;
   }
}
