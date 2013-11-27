package nme;

import nme.AssetType;

class AssetData
{

   public static var path = new Map<String,String>();
   public static var type = new Map<String,AssetType>();
   public static var useResources = ::EMBED_ASSETS::;
   private static var initialized:Bool = false;
   
   public static function initialize ():Void
    {
      if (!initialized)
      {
         ::if (assets != null)::::foreach assets::path.set ("::id::", "::resourceName::");
         type.set("::id::", Reflect.field(AssetType, "::type::".toUpperCase() ));
         ::end::::end::
         initialized = true;
      }
   }
}


