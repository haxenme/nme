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
      var info = Assets.info;

      ::if (assets != null)::
      ::foreach assets::
      info.set("::id::", createScriptAsset("::resourceName::",AssetType.::type::,::isResource::,::className::));::end::
      ::end::
   }

   public static function createScriptAsset(inPath:String, inType:AssetType, isResource:Bool, className:String)
   {
      if (!isResource)
         inPath = Assets.scriptBase + inPath;

      return new AssetInfo(inPath,inType,isResource,className);
   }
}


