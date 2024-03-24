/*
 * Copyright 2017 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.haxe.nme;

::if ANDROID_BILLING::

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingClient.FeatureType;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingFlowParams.ProductDetailsParams;
//import com.android.billingclient.api.BillingClient.SkuType;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.Purchase.PurchaseState;
import com.android.billingclient.api.ProductDetailsResponseListener;
import com.android.billingclient.api.PurchasesResponseListener;
//import com.android.billingclient.api.Purchase.PurchasesResult;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.QueryPurchasesParams;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryProductDetailsParams.Product;
//import com.android.billingclient.api.SkuDetailsParams;
//import com.android.billingclient.api.SkuDetailsResponseListener;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;


import android.text.TextUtils;
import android.util.Base64;
//import com.android.billingclient.util.BillingHelper;
import java.io.IOException;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.Signature;
import java.security.SignatureException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;



import org.haxe.nme.HaxeObject;

/**
 * Handles all the interactions with Play Store (via Billing library), maintains connection to
 * it through BillingClient and caches temporary states/data if needed
 */
public class BillingManager implements PurchasesUpdatedListener {
    // Default value of mBillingClientResponseCode until BillingManager was not yeat initialized
    public static final int BILLING_MANAGER_NOT_INITIALIZED  = -1;

    private static final String TAG = "BillingManager";

    /** A reference to BillingClient **/
    private BillingClient mBillingClient;

    /**
     * True if billing service is connected now.
     */
    private boolean mIsServiceConnected = false;

    private final HaxeObject mBillingUpdatesListener;

    private final Activity mActivity;

    //private final List<Purchase> mPurchases = new ArrayList<>();

    private Set<String> mTokensToBeConsumed;

    private int mBillingClientResponseCode = BILLING_MANAGER_NOT_INITIALIZED;

    /* BASE_64_ENCODED_PUBLIC_KEY should be YOUR APPLICATION'S PUBLIC KEY
     * (that you got from the Google Play developer console). This is not your
     * developer public key, it's the *app-specific* public key.
     *
     * Instead of just storing the entire literal string here embedded in the
     * program,  construct the key at runtime from pieces or
     * use bit manipulation (for example, XOR with some other string) to hide
     * the actual key.  The key itself is not secret information, but we don't
     * want to make it easy for an attacker to replace the public key with one
     * of their own and then fake messages from the server.
     */
    String BASE_64_ENCODED_PUBLIC_KEY = "";


    public BillingManager(Activity activity, final String inPublicKey, final HaxeObject updatesListener)
    {
        Log.d(TAG, "Creating Billing client.");
        BASE_64_ENCODED_PUBLIC_KEY = inPublicKey;
        mActivity = activity;
        mBillingUpdatesListener = updatesListener;
        mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(this).build();

        // Start setup. This is asynchronous and the specified listener will be called
        // once setup completes.
        // It also starts to report all the new purchases through onPurchasesUpdated() callback.
        startServiceConnection(new Runnable() {
            @Override public void run() {
               Log.d(TAG, "Billing client - started");
               GameActivity.sendHaxe( new Runnable() {
                   @Override
                   public void run() {
                   // Notifying the listener that billing client is ready
                   mBillingUpdatesListener.call0("onBillingClientSetupFinished");
                   //if (purchaseCap!="")
                   //   mBillingUpdatesListener.call2("onPurchasesUpdated", 0, purchaseCap);
                 } } );
 
             } } );

    }


    public static JSONObject getProductJson(ProductDetails sku) throws JSONException
    {
       JSONObject obj= new JSONObject();
       obj.put("description", sku.getDescription() );
       obj.put("sku", sku.getProductId() );
       obj.put("title", sku.getTitle() );
       obj.put("type", sku.getProductType() );
       if (sku.getProductType().equals(ProductType.INAPP))
       {
          ProductDetails.OneTimePurchaseOfferDetails  d = sku.getOneTimePurchaseOfferDetails();
          obj.put("price", d.getFormattedPrice() );
          obj.put("priceAmountMicros", d.getPriceAmountMicros() );
          obj.put("priceCurrencyCode", d.getPriceCurrencyCode() );
       }
       obj.put("name", sku.getName() );

/*
       obj.put("freeTrialPeriod", sku.getFreeTrialPeriod() );
       obj.put("introductoryPrice", sku.getIntroductoryPrice() );
       obj.put("introductoryPriceAmountMicros", sku.getIntroductoryPriceAmountMicros() );
       obj.put("introductoryPriceCycles", sku.getIntroductoryPriceCycles() );
       obj.put("introductoryPricePeriod", sku.getIntroductoryPricePeriod() );
       obj.put("subscriptionPeriod", sku.getSubscriptionPeriod() );
*/
       return obj;
    }

    public void queryProductsAsync(final String type, String [] products, final HaxeObject onResult)
    {
       Log.d(TAG, "Billing client - queryProductsAsync " + products.length);
       List<Product> plist = new ArrayList<Product>();

       for(String p : products)
       {
           //Log.d(TAG, "Billing type " + type + "/" + ProductType.SUBS + "/" + ProductType.INAPP);
           plist.add(Product.newBuilder().setProductId(p).setProductType(type).build());
       }

       final QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
          .setProductList(plist).build();

       final QueryPurchasesParams queryPurchasesParams = QueryPurchasesParams.newBuilder().setProductType(type).build();
 
       final BillingManager man = this;

       startServiceConnection(new Runnable() {
            @Override public void run() {

            mBillingClient.queryProductDetailsAsync( params,
                new ProductDetailsResponseListener() {
                    public void onProductDetailsResponse(BillingResult billingResult,
                        List<ProductDetails> productDetailsList) {

                         //Log.e(TAG, "onProductDetailsResponse");
                         int responseCode = billingResult.getResponseCode();
                         String result = "";
                         try {
                            JSONArray array= new JSONArray();
                            for(ProductDetails sku : productDetailsList)
                            {
                               JSONObject obj = getProductJson(sku);
                               array.put(obj);
                            }
                            result = array.toString();
                            //Log.e(TAG, " result=" + result );

                         } catch (JSONException e) {
                            Log.e(TAG, GameActivity.getStackTrace(e));
                            responseCode = -1;
                         }

                         final int code = responseCode;
                         final String skus = result;
                         GameActivity.queueRunnable( new Runnable() {
                           @Override public void run() {
                               onResult.call2("onSkuDetails", code, skus);
                           } } );
              } } );

           mBillingClient.queryPurchasesAsync(queryPurchasesParams,
              new PurchasesResponseListener() {
                 public void onQueryPurchasesResponse( BillingResult billingResult, List<Purchase> purchases) {
                   man.onPurchasesUpdated(billingResult, purchases);

            } } );

        } } );
    }


    /**
     * Handle a callback that purchases were updated from the Billing library
     */
    @Override
    public void onPurchasesUpdated(BillingResult billingResult, List<Purchase> purchases)
    {
       int resultCode = billingResult.getResponseCode();
       //Log.w(TAG,"onPurchasesUpdated:" + resultCode);

       String result = "";
       try
       {
          JSONArray array = new JSONArray();
          if (purchases!=null)
             for(Purchase purchase : purchases)
                 handlePurchase(purchase,array);
          result = array.toString();
       }
       catch (JSONException e)
       {
          Log.e(TAG, "Error in purchases. " + GameActivity.getStackTrace(e));
          resultCode = -1;
       }

       final String purchaseArrayCapture = result;
       final int fRcode = resultCode;
       GameActivity.sendHaxe( new Runnable() {
            @Override public void run() {
            mBillingUpdatesListener.call2("onPurchasesUpdated", fRcode, purchaseArrayCapture);
         } } );
    }

    void failedPurchase(final String sku, final int resultCode)
    {
       //final String json = details==null ? null : GameActivity.getSkuJson(details).toString();

       GameActivity.sendHaxe( new Runnable() {
            @Override public void run() {
            mBillingUpdatesListener.call2("onPurchaseFailed", sku, resultCode);
         } } );
    }


    /**
     * Start a purchase or subscription replace flow
     */
    public void initiatePurchaseFlow(final String productId, final String billingType)
    {
       Runnable queryRequest = new Runnable() {
            @Override
            public void run() {
                // Query the purchase async
                //SkuDetailsParams.Builder params = SkuDetailsParams.newBuilder();
                //params.setSkusList( Arrays.asList(skuId) ).setType(billingType);
                //mBillingClient.querySkuDetailsAsync(params.build(),

                Product p = Product.newBuilder().setProductId(productId).setProductType(billingType).build();
                final QueryProductDetailsParams prodParams = QueryProductDetailsParams.newBuilder()
                      .setProductList( Arrays.asList(p)).build();

                mBillingClient.queryProductDetailsAsync(prodParams,
                        new ProductDetailsResponseListener() {
                             public void onProductDetailsResponse(BillingResult billingResult,
                                 final List<ProductDetails> productDetailsList) {

                                if (billingResult.getResponseCode()!=BillingResponseCode.OK)
                                {
                                   failedPurchase(productId, billingResult.getResponseCode());
                                }
                                else
                                {
                                   if (productDetailsList.size()!=1)
                                   {
                                      failedPurchase(productId, -100 - productDetailsList.size());
                                   }
                                   else
                                   {
                                      // Now launch

                                      final ProductDetails productDetails = productDetailsList.get(0);
                                      final ProductDetailsParams productDetailsParams
                                         = ProductDetailsParams.newBuilder().setProductDetails(productDetails).build();
                                      Runnable purchaseFlowRequest = new Runnable() {
                                          @Override public void run() {

                                              BillingFlowParams purchaseParams = BillingFlowParams.newBuilder()
                                                   .setProductDetailsParamsList( Arrays.asList(productDetailsParams) ).build();
                                              mBillingClient.launchBillingFlow(mActivity, purchaseParams);
                                          }
                                      };

                                      executeServiceRequest(purchaseFlowRequest);
                                   }
                                }
                            }
                        });
            }
        };

        executeServiceRequest(queryRequest);
    }

    public Context getContext() {
        return mActivity;
    }

    /**
     * Clear the resources
     */
    public void destroy() {
        Log.d(TAG, "Destroying the manager.");

        if (mBillingClient != null && mBillingClient.isReady()) {
            mBillingClient.endConnection();
            mBillingClient = null;
        }
    }


    public void consumeAsync(final String purchaseToken) {
        // If we've already scheduled to consume this token - no action is needed (this could happen
        // if you received the token when querying purchases inside onReceive() and later from
        // onActivityResult()
        if (mTokensToBeConsumed == null) {
            mTokensToBeConsumed = new HashSet<>();
        } else if (mTokensToBeConsumed.contains(purchaseToken)) {
            Log.i(TAG, "Token was already scheduled to be consumed - skipping...");
            return;
        }
        mTokensToBeConsumed.add(purchaseToken);

        // Generating Consume Response listener
        final ConsumeResponseListener onConsumeListener = new ConsumeResponseListener() {
            @Override
            public void onConsumeResponse(final BillingResult result, final String purchaseToken) {
               GameActivity.sendHaxe( new Runnable() {
                  @Override public void run () {
                  // If billing service was disconnected, we try to reconnect 1 time
                  // (feel free to introduce your retry policy here).
                  mBillingUpdatesListener.call2("onConsumeFinished",purchaseToken, result.getResponseCode());
                  } } );
            }
        };

        // Creating a runnable from the request to use it inside our connection retry policy below
        Runnable consumeRequest = new Runnable() {
            @Override
            public void run() {
                ConsumeParams.Builder params = ConsumeParams.newBuilder();
                params.setPurchaseToken(purchaseToken);
                // Consume the purchase async
                mBillingClient.consumeAsync(params.build(), onConsumeListener);
            }
        };

        executeServiceRequest(consumeRequest);
    }

    /**
     * Returns the value Billing client response code or BILLING_MANAGER_NOT_INITIALIZED if the
     * clien connection response was not received yet.
     */
    public int getBillingClientResponseCode() {
        return mBillingClientResponseCode;
    }

    /**
     * Handles the purchase
     * <p>Note: Notice that for each purchase, we check if signature is valid on the client.
     * It's recommended to move this check into your backend.
     * See {@link Security#verifyPurchase(String, String, String)}
     * </p>
     * @param purchase Purchase to be handled
     */
    private void handlePurchase(Purchase purchase,  JSONArray outList)  throws JSONException
    {
       boolean valid = verifyValidSignature(purchase.getOriginalJson(), purchase.getSignature());

       Log.w(TAG, "handlePurchase " + purchase.getProducts() );
       for(String sku : purchase.getProducts() )
       {
          JSONObject obj= new JSONObject();
          obj.put("sku", sku);
          obj.put("valid", valid );
          obj.put("purchaseToken", purchase.getPurchaseToken() );
          obj.put("orderId", purchase.getOrderId() );
          obj.put("packageName", purchase.getPackageName() );
          // 0=unknown, 1=purchased, 2=pending
          obj.put("purchaseState", purchase.getPurchaseState() );
          obj.put("purchaseTime", purchase.getPurchaseTime() );
          obj.put("signature", purchase.getSignature() );
          obj.put("isAcknowledged", purchase.isAcknowledged() );
          obj.put("isAutoRenewing", purchase.isAutoRenewing() );

          outList.put(obj);
       }
    }


    public void acknowledgePurchase(final String purchaseToken)
    {
        Runnable r = new Runnable() {
            @Override
            public void run() {
              mBillingClient.acknowledgePurchase(
                  AcknowledgePurchaseParams.newBuilder()
                    .setPurchaseToken(purchaseToken)
                    .build(),
                new AcknowledgePurchaseResponseListener() {
                   @Override
                   public void onAcknowledgePurchaseResponse(BillingResult billingResult) { }
                });
                }
        };

        executeServiceRequest(r);
    }

    public void startServiceConnection(final Runnable executeOnSuccess) {
        //Log.e(TAG,"startConnection ...");
        mBillingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(BillingResult billingResult) {

                int billingResponseCode = billingResult.getResponseCode();
                //Log.w(TAG, "onBillingSetupFinished " + billingResponseCode);
                if (billingResponseCode == BillingResponseCode.OK) {
                    mIsServiceConnected = true;
                    if (executeOnSuccess != null) {
                        executeOnSuccess.run();
                    }
                }
                else  {
                   Log.w(TAG, "onBillingSetup could not setup billing" + billingResponseCode);
                }
                mBillingClientResponseCode = billingResponseCode;

            }

            @Override
            public void onBillingServiceDisconnected() {
                Log.w(TAG, "onBillingServiceDisconnected");
                mIsServiceConnected = false;
            }
        });
    }

    private void executeServiceRequest(Runnable runnable) {
        if (mIsServiceConnected) {
            runnable.run();
        } else {
            // If billing service was disconnected, we try to reconnect 1 time.
            // (feel free to introduce your retry policy here).
            startServiceConnection(runnable);
        }
    }

    /**
     * Verifies that the purchase was signed correctly for this developer's public key.
     * <p>Note: It's strongly recommended to perform such check on your backend since hackers can
     * replace this method with "constant true" if they decompile/rebuild your app.
     * </p>
     */
    private boolean verifyValidSignature(String signedData, String signature) {
        try {
            return verifyPurchaseInsecure(BASE_64_ENCODED_PUBLIC_KEY, signedData, signature);
        } catch (IOException e) {
            Log.e(TAG, "Bad purchase: " + e);
            return false;
        }
    }



    private static final String KEY_FACTORY_ALGORITHM = "RSA";
    private static final String SIGNATURE_ALGORITHM = "SHA1withRSA";

    /**
     * Verifies that the data was signed with the given signature, and returns the verified
     * purchase.
     * @param base64PublicKey the base64-encoded public key to use for verifying.
     * @param signedData the signed JSON string (signed, not encrypted)
     * @param signature the signature for the data, signed with the private key
     * @throws IOException if encoding algorithm is not supported or key specification
     * is invalid
     */
    public static boolean verifyPurchaseInsecure(String base64PublicKey, String signedData,
            String signature) throws IOException {
        
        /*
        if (TextUtils.isEmpty(signedData) || TextUtils.isEmpty(base64PublicKey)
                || TextUtils.isEmpty(signature)) {
            BillingHelper.logWarn(TAG, "Purchase verification failed: missing data.");
            return false;
        }
        */
        PublicKey key = generatePublicKey(base64PublicKey);
        return verify(key, signedData, signature);
    }

    /**
     * Generates a PublicKey instance from a string containing the Base64-encoded public key.
     *
     * @param encodedPublicKey Base64-encoded public key
     * @throws IOException if encoding algorithm is not supported or key specification
     * is invalid
     */
    public static PublicKey generatePublicKey(String encodedPublicKey) throws IOException {
        try {
            byte[] decodedKey = Base64.decode(encodedPublicKey, Base64.DEFAULT);
            KeyFactory keyFactory = KeyFactory.getInstance(KEY_FACTORY_ALGORITHM);
            return keyFactory.generatePublic(new X509EncodedKeySpec(decodedKey));
        } catch (NoSuchAlgorithmException e) {
            // "RSA" is guaranteed to be available.
            throw new RuntimeException(e);
        } catch (InvalidKeySpecException e) {
            String msg = "Invalid key specification: " + e;
            //BillingHelper.logWarn(TAG, msg);
            throw new IOException(msg);
        }
    }

    /**
     * Verifies that the signature from the server matches the computed signature on the data.
     * Returns true if the data is correctly signed.
     *
     * @param publicKey public key associated with the developer account
     * @param signedData signed data from server
     * @param signature server signature
     * @return true if the data and signature match
     */
    public static boolean verify(PublicKey publicKey, String signedData, String signature) {
        byte[] signatureBytes;
        try {
            signatureBytes = Base64.decode(signature, Base64.DEFAULT);
        } catch (IllegalArgumentException e) {
            //BillingHelper.logWarn(TAG, "Base64 decoding failed.");
            return false;
        }
        try {
            Signature signatureAlgorithm = Signature.getInstance(SIGNATURE_ALGORITHM);
            signatureAlgorithm.initVerify(publicKey);
            signatureAlgorithm.update(signedData.getBytes());
            if (!signatureAlgorithm.verify(signatureBytes)) {
                //BillingHelper.logWarn(TAG, "Signature verification failed.");
                return false;
            }
            return true;
        } catch (NoSuchAlgorithmException e) {
            // "RSA" is guaranteed to be available.
            throw new RuntimeException(e);
        } catch (InvalidKeyException e) {
            //BillingHelper.logWarn(TAG, "Invalid key specification.");
        } catch (SignatureException e) {
            //BillingHelper.logWarn(TAG, "Signature exception.");
        }
        return false;
    }





}

::else::

public class BillingManager  { }

::end::
