package nme.store;

class Purchase
{
   public var sku:String;

   public function new() { }

   public static function fromDynamic(d:Dynamic)
   {
      var p = new Purchase();
      return p;
   }
}
