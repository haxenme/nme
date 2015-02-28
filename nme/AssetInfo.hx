package nme;

import nme.utils.WeakRef;

@:nativeProperty
class AssetInfo
{
   public var path:String;
   public var className:String;
   public var type:AssetType;
   public var cache:WeakRef<Dynamic>;
   public var isResource:Bool;

   public function new(inPath:String, inType:AssetType, inIsResource:Bool, ?inClassName:String)
   {
      path = inPath;
      type = inType;
      className = inClassName;
      isResource = inIsResource;
   }

   public function uncache()
   {
      cache = null;
   }

   public function getCache() : Dynamic
   {
      if (cache==null)
         return null;
      var val = cache.get();
      if (val==null)
         cache = null;
      return val;
   }

   public function setCache(inVal:Dynamic, inWeak:Bool)
   {
      cache = new WeakRef<Dynamic>(inVal,inWeak);
   }
}


