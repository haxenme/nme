package nme.store;


class BillingManager
{
   public static var setup = false;

#if (android||ios)
   inline public static var available = true;
#else
   inline public static var available = false;
#end

   public static var purchases = new Array<Purchase>();
   public static var skuInfo:Map<String, SkuInfo>;
   public static var managedInApps:Array<String>;
   public static var managedSubs:Array<String>;
   public static var observers = new Array<BillingEvent->Void>();


   public static function init(?key:String,
         ?inManagedInApps:Array<String>,
         ?inManagedSubs:Array<String>,
         ?billingObserver:BillingEvent->Void) : Bool
   {
      trace("Billing manager init");
      managedInApps = inManagedInApps;
      managedSubs = inManagedSubs;
      skuInfo = new Map();
      if (billingObserver!=null)
         addObserver(billingObserver);
#if android
      AndroidBillingManager.init(key);
#elseif ios
      IosBillingManager.init();
      //updateSkuDetails();
#end
      return available;
   }

   public static function restorePurchases()
   {
   #if ios
      IosBillingManager.restore();
   #end
   }

   public static function fire(billingEvent:BillingEvent)
   {
      switch(billingEvent)
      {
         case StoreSetupComplete(ok):
            setup = ok;
            if (setup)
               updateSkuDetails();
         default:
      }
      for(o in observers)
         if (o!=null)
            o(billingEvent);
   }

   public static function addObserver(billingObserver:BillingEvent->Void)
   {
      observers.push(billingObserver);
   }

   public static function removeObserver(billingObserver:BillingEvent->Void) : Bool
   {
      return observers.remove(billingObserver);
   }

   public static function addPurchase(purchase:Purchase, andFire=true)
   {
      if (purchases==null)
         purchases = [];
      var found = false;
      for(i in 0...purchases.length)
         if (purchases[i].sku==purchase.sku)
         {
            purchases[i] = purchase;
            found = true;
            break;
         }
      if (!found)
         purchases.push(purchase);
      if (andFire)
         fire( PurchasesUpdated(0) );
   }

   public static function setPurchases(inPurchases:Array<Purchase>, andFire=true)
   {
      purchases = inPurchases;
      //trace("setPurchases " + inPurchases);
      if (andFire)
         fire( PurchasesUpdated(0) );
   }

   public static function acknowledgePurchase(purchase:Purchase)
   {
#if android
      AndroidBillingManager.acknowledgePurchase(purchase.purchaseToken);
#end
   }

   public static function updateSkuDetails(?itemType:ItemType)
   {
      #if android
      if (itemType==InAppItem || itemType==null)
         updateSkuDetailsList( managedInApps, InAppItem );

      if (itemType==SubscriptionItem || itemType==null)
         updateSkuDetailsList( managedSubs, SubscriptionItem );
      #else
      var allItems = managedSubs==null ? managedInApps : managedSubs;
      if (allItems!=null)
      {
         if (managedSubs!=null && managedInApps!=null)
            allItems = managedSubs.concat(managedInApps);
         // Not anymore?
         //allItems = [ for(i in allItems) nme.Lib.packageName + "." + i ]; 
         updateSkuDetailsList( allItems, InAppItem );
      }
      #end
   }

   public static function updateSkuDetailsList(skuList:Array<String>, itemType:ItemType)
   {
      if (skuList!=null)
      {
#if android
         AndroidBillingManager.querySkuDetails(itemType==SubscriptionItem ? "subs" : "inapp", skuList );
         return;
#elseif ios
         IosBillingManager.querySkuDetails(itemType==SubscriptionItem ? "subs" : "inapp", skuList );
         return;
#end
      }

      fire( SkuDetailsUpdated(false) );
   }

   public static function startPurchase(sku:String, ?itemType:ItemType)
   {
      if (itemType==null)
      {
         if (managedSubs!=null && managedSubs.indexOf(sku)>=0)
            itemType = SubscriptionItem;
         else
            itemType = InAppItem;
      }

#if android
      AndroidBillingManager.initiatePurchaseFlow(sku, itemType==SubscriptionItem?"subs":"inapp");
#elseif ios
      IosBillingManager.initiatePurchaseFlow(sku, itemType==SubscriptionItem);
#else
      fire( PurchaseFailed(sku, -99) );
#end
   }

   public static function startConsume(purchaseToken)
   {
#if android
      AndroidBillingManager.consumeAsync(purchaseToken);
#else
      fire( ConsumeComplete(purchaseToken, -99) );
#end
   }


   public static function close()
   {
      if (setup)
      {
#if android
         AndroidBillingManager.close();
#end
      }
   }

}

