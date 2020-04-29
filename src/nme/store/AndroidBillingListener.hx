package nme.store;

typedef AndroidBillingListener =
{
   public function onBillingClientSetupFinished() : Void;
   public function onPurchasesUpdated(resultCode:Int, purchases:Array<Purchase>) : Void;
   public function onPurchaseFailed(sku:String, resultCode:Int) : Void;
   public function onConsumeFinished(purchaseToken:String, responseCode:Int) : Void;
}

