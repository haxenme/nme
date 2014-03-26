package nme;


import nme.Assets;
import nme.AssetType;



class AssetData
{
   public static function create():Void
   {
      var info = Assets.info;

      ::if (assets != null)::
      ::foreach assets::
      info.set("::id::", new AssetInfo("::resourceName::",AssetType.::type::,::embed::,"nme.NME_::flatName::"));::end::
      ::end::
   }
}


::foreach assets::::if (type == "image")::class NME_::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0); } }::else::class NME_::flatName:: extends ::flashClass:: { }::end::
::end::
