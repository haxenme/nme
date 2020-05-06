package nme.store;

enum BillingEvent
{
   StoreSetupComplete(ok:Bool);
   SkuDetailsUpdated(ok:Bool);
   PurchasesUpdated(errorCode:Int);
   PurchaseFailed(sku:String, code:Int);
   ConsumeComplete(purchaseToken:String, responseCode:Int);
}

