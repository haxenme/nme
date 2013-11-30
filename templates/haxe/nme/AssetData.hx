package nme;


class AssetData
{
   public static function create():Void
   {
      var info = Assets.info;
      Assets.useResources = ::EMBED_ASSETS::;

      ::if (assets != null)::
      ::foreach assets::
      info.set("::id::", new AssetInfo("::resourceName::",AssetType.::type::));::end::
      ::end::
   }
}


