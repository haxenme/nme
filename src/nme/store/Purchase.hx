package nme.store;

class Purchase
{
   public var jsonData:Dynamic;
   public var sku(get,null):String;

   public function new(?inJsonData:Dynamic)
   {
      jsonData = inJsonData;
   }

   public function get_sku():String
   {
      if (jsonData==null)
         return null;
      return jsonData.productId;
   }

   public static function fromDynamic(d:Dynamic)
   {
      return new Purchase(d);
   }

   public function toString() return 'Purchase($jsonData)';
}
