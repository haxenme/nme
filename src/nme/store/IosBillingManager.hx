package nme.store;

@:cppInclude("./IosStore.mm")
@:depend("./IosStore.mm")
@:buildXml('<include name="${haxelib:nme-store-utils}/nmestoreutils.xml"/>')
class IosBillingManager
{
   // billingType strings
   public inline static var INAPP = "inapp";
   public inline static var SUBS = "subs";


   @:native("::initStore")
   extern public static function initStore(cert:cpp.Pointer<cpp.UInt8>, cerLen:Int) : Void ;

   public static function init() : Void
   {
      var bytes = nme.Assets.getBytes("AppleIncRootCertificate");
      var data = bytes.getData();
      initStore(cpp.NativeArray.address(data,0), data.length );
      BillingManager.fire( StoreSetupComplete(true) );
   }

   @:native("::billingQuery")
   extern public static function billingQuery(itemType:String, skuList:Array<String>) : Void ;
   public static function querySkuDetails(itemType:String, skuList:Array<String>) : Void
   {
      trace('querySkuDetails3 $skuList');
      billingQuery(itemType, skuList);
   }

   public static function acknowledgePurchase(purchaseToken:String)
   {
      //billingAcknowledge(purchaseToken);
   }


   @:native("::nativeRestore")
   extern static function nativeRestore() : Void;
   public static function restore()
   {
      nativeRestore();
   }

   @:keep
   function onSkuError(name:String) :Void
   {
      trace("Error wirh SKU:" + name);
      BillingManager.fire( SkuDetailsUpdated(false) );
   }

   @:keep
   static function addSkuDetails(name:String, title:String, description:String, price:String,  subscriptionPeriod:String) :Void
   {
      var sku = new SkuInfo({
         sku:name,
         title:title,
         description:description,
         price:price,
         subscriptionPeriod:subscriptionPeriod,
         type: subscriptionPeriod==null ? "inapp" : "subs"
      });

      BillingManager.skuInfo.set(name,sku);
   }

   @:keep
   static function onSkuDetailsDone( ) :Void
   {
      BillingManager.fire( SkuDetailsUpdated(true) );
   }


   @:keep
   public static function onPurchase(sku:String, valid:Bool, pending:Bool)
   {
      var purchase = new Purchase({
         sku:sku,
         valid:valid,
         purchaseState:pending ? 2 : 1,
      });
      BillingManager.addPurchase(purchase);
   }


   @:keep
   public static function onBadVerify(sku:String)
   {
      BillingManager.fire( PurchaseFailed(sku,2) );
   }


   @:keep
   public static function onPurchaseDeferred(sku:String)
   {
      onPurchase(sku, true, true );
   }


   @:native("::requestPayment")
   extern static function requestPayment(inProduct:String, isSubscription:Bool, quantity:Int):Void;

   public static function initiatePurchaseFlow(skuId:String, isSubscription:Bool) : Void
   {
      requestPayment(skuId,isSubscription,1);
   }



   /*

   @:keep
   function onBillingClientSetupFinished()
   {
      BillingManager.fire( StoreSetupComplete(true) );
   }


   @:keep
   function onPurchasesUpdated(code:Int, jsonDetails:String)
   {
      try
      {
         var details:Array<Dynamic> = haxe.Json.parse(jsonDetails);
         if (details!=null)
         {
            var haxePurchases = new Array<Purchase>();
            for(p in details)
               haxePurchases.push( new Purchase(p) );

            BillingManager.setPurchases(haxePurchases);
            return;
         }
      }
      catch(e:Dynamic)
      {
         trace("error with purchases:" + e);
      }
      BillingManager.fire( PurchasesUpdated(code) );
   }

   @:keep
   function onPurchaseFailed(sku:String, code:Int)
   {
      BillingManager.fire( PurchaseFailed(sku, code) );
   }

   @:keep
   function onConsumeFinished(purchaseToken:String, responseCode:Int)
   {
      BillingManager.fire( ConsumeComplete(purchaseToken, responseCode) );
   }




   public static function close() : Void
   {
      billingClose();
   }


   public static function consumeAsync(purchaseToken:String) : Void
   {
      billingConsume(purchaseToken);
   }

   public static  function getBillingClientResponseCode() : Int
   {
      return billingClientCode();
   }
   */
}



