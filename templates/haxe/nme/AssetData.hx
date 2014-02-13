package nme;

#if (waxe && !nme)
import wx.Assets;
import wx.AssetInfo;
import wx.AssetType;
#else
import nme.Assets;
import nme.AssetInfo;
import nme.AssetType;
#end

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

#if flash
::foreach assets::::if (embed)::::if (isImage)::class ::flatName:: extends flash.display.BitmapData { public function new()super(0,0); }::else::class ::flatName:: extends ::flashClass:: { }::end::::end::
::end::
#end


