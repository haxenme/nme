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

      ::foreach libraryHandlers::
      Assets.addLibraryFactory( ::type::, function(id) return new ::handler::(id) );
      ::end::

      Assets.loadAssetList();
   }
}

#if flash
::foreach assets::::if (embed)::@:keep ::if (isImage)::class ::flatName:: extends flash.display.BitmapData { public function new()super(0,0); }::else::class ::flatName:: extends ::flashClass:: { }::end::::end::
::end::
#end


