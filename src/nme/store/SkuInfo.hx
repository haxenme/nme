package nme.store;

class SkuInfo
{
   public var description:String;
   //public var freeTrialPeriod:String;
   //public var introductoryPrice:String;
   //public var introductoryPriceAmountMicros:String;
   //public var introductoryPriceCycles:String;
   //public var introductoryPricePeriod:String;
   public var name:String;
   public var price:String;
   public var priceAmountMicros:String;
   public var priceCurrencyCode:String;
   public var sku:String;
   //public var subscriptionPeriod:String;
   public var title:String;
   public var type:String;

   public function new(?d:{ })
   {
      if (d!=null)
         for(f in Reflect.fields(d))
            Reflect.setField(this, f, Reflect.field(d,f) );
   }

   public function toString() return 'SkuInfo($sku:$description @ $price)';
}

