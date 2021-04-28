#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

#import "RMAppReceipt.h"
#import "RMStoreTransaction.h"
#import "RMStoreAppReceiptVerifier.h"

typedef nme::store::IosBillingManager_obj BM;

@interface StoreObserver: NSObject<SKPaymentTransactionObserver,SKProductsRequestDelegate> {
}
@property (nonatomic, strong) SKProductsRequest *request;
@property (nonatomic, strong) NSArray<SKProduct *> *products;

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions;
- (void)validateProductIdentifiers:(NSSet *)productIdentifiers;
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;
- (void)requestPaymentFor:(NSString *)sku withQuantity:(int)quantity;

@end

static StoreObserver *sgStore = 0;

static RMStoreAppReceiptVerifier *sgReceiptVerifier = 0;


void verifyTransaction(SKPaymentTransaction *transaction)
{
   [sgReceiptVerifier verifyTransaction:transaction
               success: ^{
                   NSLog(@"paymentQueue transaction good");
                   SKPayment *payment = transaction.payment;
                   NSString* product = payment.productIdentifier;
                   BM::onPurchase(product,true,false);
                   [ [SKPaymentQueue defaultQueue]  finishTransaction:transaction];
               }
               failure: ^(NSError *err) {
                   NSLog(@"paymentQueue transaction bad: %@",[err localizedDescription]);
                   SKPayment *payment = transaction.payment;
                   NSString* product = payment.productIdentifier;
                   BM::onPurchase(product,false,false);
                   [ [SKPaymentQueue defaultQueue]  finishTransaction:transaction];
               } ];
}


@implementation StoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
   NSLog(@"paymentQueue %@", transactions);

   for(SKPaymentTransaction *transaction in transactions)
   {
      SKPayment *payment = transaction.payment;
      NSString* product = payment.productIdentifier;
      NSLog(@"->product %@", product);

      switch (transaction.transactionState)
      {
         case SKPaymentTransactionStatePurchased:
             NSLog(@"->purchased");
             verifyTransaction(transaction);
             break;
         
         case SKPaymentTransactionStateFailed:
             NSLog(@"paymentQueue transaction failed: %@",[transaction.error localizedDescription]);
             BM::onPurchase(product,false,false);
             [ [SKPaymentQueue defaultQueue]  finishTransaction:transaction];
             break;

         case SKPaymentTransactionStateRestored:
             NSLog(@"->restored");
             verifyTransaction(transaction);
             break;

         case SKPaymentTransactionStateDeferred:
             NSLog(@"->deferred");
             BM::onPurchaseDeferred(product);
             [ [SKPaymentQueue defaultQueue]  finishTransaction:transaction];
             break;
         default:
             NSLog(@"->unknown %@ %@", transaction, payment);
             break;
      }
   }
}


// Custom method.
- (void)validateProductIdentifiers:(NSSet *)productIdentifiers
{
    NSLog(@"Validating products: %@", productIdentifiers);
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
        initWithProductIdentifiers:productIdentifiers];

    // Keep a strong reference to the request.
    self.request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

static NSString *priceToString(SKProduct *product)
{
   NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
   [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
   [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
   [numberFormatter setLocale:product.priceLocale];
   return [numberFormatter stringFromNumber:product.price];
}


// SKProductsRequestDelegate protocol method.
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
   @autoreleasepool {
    NSLog(@"Got response products: %@",response.products);
    bool found = false;
    for(SKProduct *product in response.products)
    {
       BM::addSkuDetails( 
          product.productIdentifier,
          product.localizedTitle,
          product.localizedDescription,
          priceToString( product ), 
          String()
       );
       found = true;
    }
    if (found)
       BM::onSkuDetailsDone( );


    self.products = response.products;

    NSLog(@"Got response errors: %@",response.invalidProductIdentifiers);
    for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
        // Handle any invalid product identifiers.
    }
  }
}


- (void)requestPaymentFor:(NSString *)sku withQuantity:(int)quantity
{
   NSLog(@"requestPaymentFor %@", sku);
   if (self.products!=nil)
   {
      for(SKProduct *product in self.products)
      {
         if ( [product.productIdentifier isEqualToString:sku] )
         {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
             payment.quantity = quantity;
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            return;
         }
      }
      NSLog(@"requestPaymentFor - could not fund product");
   }
   else
      NSLog(@"requestPaymentFor - no products found");

   BM::onPurchase(sku,false,false);
}

@end


void initStore(const unsigned char *inData, int inDataLength)
{
   NSLog(@"Init!");
   sgStore = [[StoreObserver alloc] init ];
   NSData* data = [NSData dataWithBytes:inData length:inDataLength];
   [RMAppReceipt setAppleRootCertificateData:data];
   sgReceiptVerifier = [[RMStoreAppReceiptVerifier alloc] init];
   [ [SKPaymentQueue defaultQueue] addTransactionObserver:sgStore];
   NSLog(@"OK!");
}


void requestPayment( ::String inProduct, bool isSubscription, int quantity=1)
{
   [sgStore requestPaymentFor:inProduct withQuantity:quantity ];
}


void billingQuery( ::String inType, ::Array< ::String> inSkus)
{
   NSMutableSet *skus = [[NSMutableSet alloc] init];
   NSLog(@"billingQuery..");
   printf("sku count: %d\n", inSkus->length);
   for(int i=0;i<inSkus->length;i++)
   {
      NSString *str = inSkus[i];
      [skus addObject:str];
   }
   NSLog(@"Validate..");
   [sgStore validateProductIdentifiers:skus];
}

void nativeRestore()
{
   NSLog(@"restore purchases...");
   [ [SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

