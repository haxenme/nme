// NmeBridgingHeader.h
// Exposes C functions (implemented in the hxcpp-compiled library) to Swift.
// These are called from IosStoreKit2.swift to fire events into the Haxe runtime.

#ifndef NmeBridgingHeader_h
#define NmeBridgingHeader_h

#include <stdbool.h>

// Called when a purchase completes or fails.
// valid=true means the transaction is verified; pending=true means deferred.
extern void nme_store_on_purchase(const char* sku, bool valid, bool pending);

// Called once per product during a SKU details query.
// period is an ISO 8601 duration string (e.g. "P1M") or empty for non-subscription products.
extern void nme_store_add_sku_detail(const char* name, const char* title,
                                      const char* desc, const char* price,
                                      const char* period);

// Called when a SKU details query has finished sending all products.
extern void nme_store_on_sku_done(void);

#endif /* NmeBridgingHeader_h */
