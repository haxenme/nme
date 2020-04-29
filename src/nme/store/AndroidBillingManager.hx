package nme.store;

import nme.JNI;

#if !androidBilling
#error "Please set androidBilling in your project"
#end


class BillingWrapper
{
   var listener:AndroidBillingListener;

   public function new(inListener:AndroidBillingListener)
      listener = inListener;

   @:keep
   function onPurchasesUpdated(purchases:Array<String>)
   {
      var haxePurchases = new Array<Purchase>();
      for(p in purchases)
      {
         var d:Dynamic = haxe.Json.parse(p);
         haxePurchases.push( Purchase.fromDynamic(d) );
      }
      listener.onPurchasesUpdated(haxePurchases);
   }

   @:keep
   function onBillingClientSetupFinished()
      listener.onBillingClientSetupFinished();

   @:keep
   function onConsumeFinished(purchaseToken:String, responseCode:Int)
      listener.onConsumeFinished(purchaseToken, responseCode);

}

typedef SkuDetailsCallback = {
    function onSkuDetails(responseCode:Int, jsonDetails:String) :Void;
}


class AndroidBillingManager
{
   // billingType strings
   public inline static var INAPP = "inapp";
   public inline static var SUBS = "subs";

   public static function init(publicKeyString, inListener:AndroidBillingListener) : Void
   {
      billingInit(publicKeyString, new BillingWrapper(inListener) );
   }

   public static function close() : Void
   {
      billingClose();
   }

   public static function initiatePurchaseFlow(skuId:String, billingType:String) : Void
   {
      billingPurchase(skuId, billingType);
   }


   public static function querySkuDetails(itemType:String, skuList:Array<String>, onSkuDetails:SkuDetailsCallback ) : Void
   {
      billingQuery(itemType, skuList, onSkuDetails);
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
}


