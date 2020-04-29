package nme.store;

class Purchase
{
   public var jsonData:Dynamic;
   public var sku(get,null):String;

   public function new(?inJsonData:String)
   {
      if (inJsonData!=null)
         jsonData = haxe.Json.parse(jsonData);
   }

   public function get_sku():String
   {
      if (jsonData==null)
         return null;
      return jsonData.productId;
   }

   public static function fromDynamic(d:Dynamic)
   {
      var string:String = d;
      var p = new Purchase(string);
      return p;
   }

   public function toString() return 'Purchase($jsonData)';
}
