package nme;


class AssetData
{
   public static function create():Void
   {
      var info = Assets.info;

      ::if (assets != null)::
      ::foreach assets::
      info.set("::id::", new AssetInfo("::resourceName::",AssetType.::type::,::isResource::,::className::));::end::
      ::end::
   }
}

::foreach assets::::if (embed)::::if (isImage)::class ::flatName:: extends flash.display.BitmapData { public function new()super(0,0); }::else::class ::flatName:: extends ::flashClass:: { }::end::::end::
::end::



