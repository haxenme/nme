package nme;


class AssetData
{
   public static function create():Void
   {
      var info = Assets.info;

      ::if (assets != null)::
      ::foreach assets::
      info.set("::id::", new AssetInfo("::resourceName::",AssetType.::type::,::embed::));::end::
      ::end::
   }
}


