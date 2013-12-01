package nme;

import nme.utils.WeakRef;

class AssetInfo
{
   public var path:String;
   public var className:String;
   public var type:AssetType;
   public var cache:WeakRef<Dynamic>;

   public function new(inPath:String, inType:AssetType, ?inClassName:String)
   {
      path = inPath;
      type = inType;
      className = inClassName;
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


