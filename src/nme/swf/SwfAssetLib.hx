package nme.swf;

import nme.AssetLib;
import nme.display.BitmapData;
import nme.display.Loader;
import nme.display.MovieClip;
import nme.events.Event;
import nme.net.URLRequest;
import flash.system.ApplicationDomain;
import nme.system.LoaderContext;
import nme.Assets;
import nme.AssetType;

class SwfAssetLib extends AssetLib
{
   private var context:LoaderContext;
   private var id:String;
   private var loader:Loader;
   
   public function new(inId:String)
   {
      super ();
      id = inId;
   }

   public override function exists(id:String, type:AssetType):Bool
   {
      if (id=="" && type==MOVIE_CLIP)
         return true;
 
      if (type==IMAGE || type==MOVIE_CLIP)
         return loader.contentLoaderInfo.applicationDomain.hasDefinition(id);

      return false;
   }
   
   
   public override function getBitmapData(id:String):BitmapData
   {
      var bmd = Type.createEmptyInstance(cast loader.contentLoaderInfo.applicationDomain.getDefinition(id));
      return bmd;
   }

   public override function getMovieClip (id:String):MovieClip
   {
      if (id=="")
         return cast loader.content;
      else
         return cast Type.createInstance(loader.contentLoaderInfo.applicationDomain.getDefinition(id), []);
   }
   
   
   public override function load(onLoad:AssetLib -> Void):Void
   {
      context = new LoaderContext(false, ApplicationDomain.currentDomain, null);
      context.allowCodeImport = true;

      loader = new Loader();
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function (_) onLoad(this) );

      if (Assets.isLocal(id,BINARY))
         loader.loadBytes(Assets.getBytes(id), context);
      else
         loader.load(new URLRequest(Assets.getPath(id)), context);
   }
}

