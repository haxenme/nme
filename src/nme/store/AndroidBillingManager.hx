package nme.store;

import nme.JNI;
import nme.store.BillingEvent;

#if !androidBilling
#error "Please set androidBilling in your project"
#end



class AndroidBillingManager
{
   // billingType strings
   public inline static var INAPP = "inapp";
   public inline static var SUBS = "subs";

   // result codes
   public static inline var OK = 0;
   public static inline var USER_CANCELED = 1;
   public static inline var ITEM_ALREADY_OWNED = 7;
   public static inline var ITEM_NOT_OWNED = 8;
   public static inline var ITEM_UNAVAILABLE = 4;
   public static inline var SERVICE_DISCONNECTED = -1;
   public static inline var SERVICE_UNAVAILABLE = 2;
   public static inline var UNAVAILABLE = 3;
   public static inline var DEVELOPER_ERROR = 3;
   public static inline var ERROR = 6;
   public static inline var FEATURE_NOT_SUPPORTED = -2;

   static var manager:AndroidBillingManager;


   function new() { }


   public static function init(publicKeyString ) : Void
   {
      manager = new AndroidBillingManager();

      billingInit(publicKeyString,manager);
   }

   public static function querySkuDetails(itemType:String, skuList:Array<String>) : Void
   {
      billingQuery(itemType, skuList, manager);
   }

   public static function acknowledgePurchase(purchaseToken:String)
   {
      billingAcknowledge(purchaseToken);
   }

   @:keep
   function onSkuDetails(responseCode:Int, jsonDetails:String) :Void
   {
      if (responseCode!=0)
      {
         trace("Error getting skuDetails:" + responseCode);
      }
      else
      {
         try
         {
            var details:Array<Dynamic> = haxe.Json.parse(jsonDetails);
            if (details!=null)
            {
               for(d in details)
                  BillingManager.skuInfo.set(d.sku,new SkuInfo(d));
            }
            BillingManager.fire( SkuDetailsUpdated(true) );
            return;
         }
         catch(e:Dynamic)
         {
            trace("Error parsing skuDetails:" + e);
         }
      }
      BillingManager.fire( SkuDetailsUpdated(false) );
   }

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

   public static function initiatePurchaseFlow(skuId:String, billingType:String) : Void
   {
      billingPurchase(skuId,billingType);
   }



   public static function consumeAsync(purchaseToken:String) : Void
   {
      billingConsume(purchaseToken);
   }

   public static  function getBillingClientResponseCode() : Int
   {
      return billingClientCode();
   }


   static var billingInit = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingInit", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V");
   static var billingClose = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingClose", "()V");
   static var billingPurchase = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingPurchase", "(Ljava/lang/String;Ljava/lang/String;)V");
   static var billingQuery = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingQuery", "(Ljava/lang/String;[Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V");
   static var billingConsume = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingConsume", "(Ljava/lang/String;)V");
   static var billingClientCode = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingClientCode", "()I");
   static var billingAcknowledge = JNI.createStaticMethod("org/haxe/nme/GameActivity", "billingAcknowledge", "(Ljava/lang/String;)V");
}


