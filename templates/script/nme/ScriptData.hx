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

class ScriptData
{
   public var resourceBase = "";

   public static function create():Void
   {
      Assets.loadScriptAssetList2();
   }
}


