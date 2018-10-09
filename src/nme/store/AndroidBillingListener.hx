package nme.store;

typedef AndroidBillingListener =
{
   public function onPurchasesUpdated(purchases:Array<Purchase>) : Void;
   public function onBillingClientSetupFinished() : Void;
   public function onConsumeFinished(purchaseToken:String, responseCode:Int) : Void;
}

