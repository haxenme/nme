#import <UIKit/UIKit.h>

typedef nme::store::IosBillingManager_obj BM;

// Swift entry points - implemented in IosStoreKit2.swift via @_silgen_name
extern "C" void nme_swift_init_store(void);
extern "C" void nme_swift_query_products(const char** skus, int count);
extern "C" void nme_swift_purchase(const char* sku);
extern "C" void nme_swift_restore(void);

// Callbacks invoked from Swift back into the Haxe/hxcpp runtime
extern "C" void nme_store_on_purchase(const char* sku, bool valid, bool pending)
{
   hx::NativeAttach haxe;
   BM::onPurchase(String(sku), valid, pending);
}

extern "C" void nme_store_add_sku_detail(const char* name, const char* title,
                                          const char* desc, const char* price,
                                          const char* period)
{
   hx::NativeAttach haxe;
   BM::addSkuDetails(String(name), String(title), String(desc), String(price),
                     period && *period ? String(period) : String());
}

extern "C" void nme_store_on_sku_done(void)
{
   hx::NativeAttach haxe;
   BM::onSkuDetailsDone();
}

void nativeInitStore()
{
   nme_swift_init_store();
}

void requestPayment(::String inProduct, bool isSubscription, int quantity=1)
{
   nme_swift_purchase(inProduct.c_str());
}

void billingQuery(::String inType, ::Array<::String> inSkus)
{
   int n = inSkus->length;
   const char** skus = new const char*[n];
   for (int i = 0; i < n; i++)
      skus[i] = inSkus[i].c_str();
   nme_swift_query_products(skus, n);
   delete[] skus;
}

void nativeRestore()
{
   nme_swift_restore();
}

