package nme.store;

class Purchase
{
   public var sku:String;
   public var purchaseToken:String;
   public var isAcknowledged:Bool;
   public var valid:Bool;
   public var orderId:String;
   public var packageName:String;
   public var purchaseTime:Int;
   public var signature:String;
   public var isAutoRenewing:Bool;

   // 0=unknown, 1=purchased, 2=pending
   public var purchaseState:Int;


   public function new(?d:{ })
   {
      if (d!=null)
         for(f in Reflect.fields(d))
            Reflect.setField(this, f, Reflect.field(d,f) );
   }

   public function isPurchased()
   {
      return valid && purchaseState==1;
   }

   public function isPending()
   {
      return purchaseState==2;
   }


   public function acknowledge()
   {
      if (purchaseToken!=null && purchaseToken!="" && !isAcknowledged)
      {
         isAcknowledged = true;
         BillingManager.acknowledgePurchase(this);
      }
   }

   public function toString() return 'Purchase($sku/$packageName :' + (isPurchased()?"owned":"error") +')';
}
