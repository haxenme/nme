package org.haxe.nme;


import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.Window;
import android.widget.FrameLayout;
import android.view.ViewGroup;
import android.view.Gravity;
import android.view.ViewGroup.LayoutParams;
import android.widget.RelativeLayout;
import android.view.WindowManager;
import android.widget.VideoView;
import android.net.Uri;
import android.widget.EditText;
import android.text.Editable;
import android.text.InputType;
import android.text.SpanWatcher;
import android.text.Spanned;
import android.text.Spannable;
import android.view.KeyEvent;
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.Math;
import java.lang.Runnable;
import java.util.HashMap;
import java.util.Locale;
import java.util.ArrayList;
import org.haxe.nme.Value;
import java.net.NetworkInterface;
import java.net.InetAddress;
import java.net.Inet4Address;
import java.util.Enumeration;
import java.util.List;
import android.util.SparseArray;
import org.haxe.extension.Extension;
import android.os.Build;
import android.text.TextWatcher;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import java.io.StringWriter;
import java.io.PrintWriter;

public class GameActivity extends ::GAME_ACTIVITY_BASE::
implements SensorEventListener
{
   static final String TAG = "GameActivity";

   private static final int KEYBOARD_OFF = 0;
   private static final int KEYBOARD_DUMB = 1;
   private static final int KEYBOARD_SMART = 2;
   private static final int KEYBOARD_NATIVE = 3;

   private static final String GLOBAL_PREF_FILE = "nmeAppPrefs";
   private static final int DEVICE_ORIENTATION_UNKNOWN = 0;
   private static final int DEVICE_ORIENTATION_PORTRAIT = 1;
   private static final int DEVICE_ORIENTATION_PORTRAIT_UPSIDE_DOWN = 2;
   private static final int DEVICE_ORIENTATION_LANDSCAPE_RIGHT = 3;
   private static final int DEVICE_ORIENTATION_LANDSCAPE_LEFT = 4;
   private static final int DEVICE_ORIENTATION_FACE_UP = 5;
   private static final int DEVICE_ORIENTATION_FACE_DOWN = 6;
   private static final int DEVICE_ROTATION_0 = 0;
   private static final int DEVICE_ROTATION_90 = 1;
   private static final int DEVICE_ROTATION_180 = 2;
   private static final int DEVICE_ROTATION_270 = 3;

   protected static GameActivity activity;
   static AssetManager mAssets;
   static Activity mContext;
   static DisplayMetrics metrics;
   static HashMap<String, Class> mLoadedClasses = new HashMap<String, Class>();
   static SensorManager sensorManager;
   static android.text.ClipboardManager mClipboard;
   private static List<Extension> extensions;
   
   public Handler mHandler;
   RelativeLayout mContainer;
   int            mBackground;
   MainView       mView;

   boolean        videoVpSet = false;
   int            videoX = 0;
   int            videoY = 0;
   int            videoW = 0;
   int            videoH = 0;

   class NmeText extends EditText
   {
       GameActivity activity;
       public NmeText(GameActivity context) { super( (Context)context);  activity=context; }
       @Override protected void onSelectionChanged(int selStart, int selEnd) {
          if (activity!=null)
             activity.onSelectionChanged(selStart,selEnd);
       }
   }

   ArrayList<Runnable> mOnDestroyListeners;
   static SparseArray<IActivityResult> sResultHandler = new SparseArray<IActivityResult>();
   
   private static float[] accelData = new float[3];
   private static int bufferedDisplayOrientation = -1;
   private static int bufferedNormalOrientation = -1;
   private static float[] inclinationMatrix = new float[16];
   private static float[] magnetData = new float[3];
   //private static float[] orientData = new float[3];
   private static float[] rotationMatrix = new float[16];
   private Sound _sound;
   
   public NMEVideoView   mVideoView;
   
   public EditText mKeyInTextView;
   public int mDefaultInputType =
     InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
   public boolean  mTextUpdateLockout = false;
   public boolean  mIncrementalText = true;
   boolean ignoreTextReset = false;

   public void onCreate(Bundle state)
   {
      super.onCreate(state);

      Log.d(TAG,"==== onCreate ===== " + this);
      
      activity = this;
      ::if ANDROIDVIEW::
      mContext = getActivity();
      mAssets = null;
      //setRetainInstance(true);
      ::else::
      mContext = this;
      mAssets = getAssets();
      requestWindowFeature(Window.FEATURE_NO_TITLE);
      getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
      ::end::

      _sound = new Sound(mContext);

      mHandler = new Handler();
      ::if (WIN_ALPHA_BUFFER)::
      mBackground = 0x00000000;
      ::else::
      mBackground = 0xff000000;
      ::end::
      
      //getResources().getAssets();
      
      metrics = new DisplayMetrics();
      mContext.getWindowManager().getDefaultDisplay().getMetrics(metrics);

      ::if WIN_FULLSCREEN::::if (ANDROID_TARGET_SDK_VERSION >= 19)::
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT)
         mContext.getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
      ::end::::end::
      
      Extension.assetManager = mAssets;
      Extension.callbackHandler = mHandler;
      Extension.mainActivity = this;
      Extension.mainContext = this;
      Extension.packageName = getApplicationContext().getPackageName();
      
      mClipboard = (android.text.ClipboardManager) mContext.getSystemService(Context.CLIPBOARD_SERVICE);

      // Pre-load these, so the C++ knows where to find them
      
      ::foreach ndlls:: ::if (!isStatic)::
      ::if (DEBUG)::Log.v(TAG,"Loading ::name::...");::end::
      System.loadLibrary("::name::");::end::::end::
      org.haxe.HXCPP.run("ApplicationMain");
      
      mContainer = new RelativeLayout(mContext);


      mTextUpdateLockout = true;
      mKeyInTextView = new NmeText ( this );
      mKeyInTextView.setText("*");
      mKeyInTextView.setMinLines(1);
      //mKeyInTextView.setMaxLines(1);
      mKeyInTextView.setFocusable(true);
      mKeyInTextView.setHeight(0);
      mKeyInTextView.setInputType(mDefaultInputType); //text input
      //mKeyInTextView.setImeOptions(EditorInfo.IME_ACTION_SEND);
      mKeyInTextView.setSelection(1);
      mContainer.addView(mKeyInTextView);
      addTextListeners();
      mTextUpdateLockout = false;


      mView = new MainView(mContext, this, (mBackground & 0xff000000)==0 );
      Extension.mainView = mView;

      mContainer.addView(mView, new LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT) );

      getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN);//remove keyboard at start
      //mView.requestFocus();

      //weak ref instances?
      sensorManager = (SensorManager)mContext.getSystemService(Context.SENSOR_SERVICE);

      ::if !(ANDROIDVIEW)::
      setContentView(mContainer);
      ::end::

     if (extensions == null)
     {
         extensions = new ArrayList<Extension> ();
         ::foreach ANDROID_EXTENSIONS::
         extensions.add (new ::__current__:: ());::end::
     }

     for(Extension extension : extensions)
        extension.onCreate(state);
       
     Uri link = getIntentAppLink();
     if(link != null)
        NME.setLaunchAppLink(link.toString());
   }

   ::if ANDROIDVIEW::
   public View onCreateView(android.view.LayoutInflater inflater, ViewGroup group, Bundle saved)
   {
      // Check to see if we are being recreated - need to remove from old view...
      if (mContainer.getParent()!=null)
      {
         Log.v(TAG,"Recycle container view");
         ViewGroup parent = (ViewGroup)mContainer.getParent();
         parent.removeView(mContainer);
      }
      return mContainer;
   }
   ::end::

    ::if ANDROID_BILLING::
    BillingManager mBillingManager;

    public static void billingInit(String inPublicKey, HaxeObject inUpdatesListener)
    {
       activity.mBillingManager = new BillingManager(activity, inPublicKey, inUpdatesListener);
    }
    public static void billingClose()
    {
       activity.mBillingManager.destroy();
    }
    public static void billingPurchase(String skuId, String billingType)
    {
       activity.mBillingManager.initiatePurchaseFlow(skuId, billingType);
    }
    public static void billingQuery(String itemType, String[] skuArray, final HaxeObject onResult)
    {
       activity.mBillingManager.querySkuDetailsAsync(itemType, java.util.Arrays.asList(skuArray),
          new com.android.billingclient.api.SkuDetailsResponseListener() {
             String result = "";
             @Override
             public void onSkuDetailsResponse(int responseCode, List<com.android.billingclient.api.SkuDetails> skuDetailsList) {
                try {
                   JSONArray array= new JSONArray();
                   for(com.android.billingclient.api.SkuDetails sku : skuDetailsList)
                   {
                      JSONObject obj= new JSONObject();
                      obj.put("description", sku.getDescription() );
                      obj.put("freeTrialPeriod", sku.getFreeTrialPeriod() );
                      obj.put("introductoryPrice", sku.getIntroductoryPrice() );
                      obj.put("introductoryPriceAmountMicros", sku.getIntroductoryPriceAmountMicros() );
                      obj.put("introductoryPriceCycles", sku.getIntroductoryPriceCycles() );
                      obj.put("introductoryPricePeriod", sku.getIntroductoryPricePeriod() );
                      obj.put("price", sku.getPrice() );
                      obj.put("priceAmountMicros", sku.getPriceAmountMicros() );
                      obj.put("priceCurrencyCode", sku.getPriceCurrencyCode() );
                      obj.put("sku", sku.getSku() );
                      obj.put("subscriptionPeriod", sku.getSubscriptionPeriod() );
                      obj.put("title", sku.getTitle() );
                      obj.put("type", sku.getType() );
                      array.put(obj);
                   }
                   result = array.toString();

                } catch (JSONException e) {
                   Log.e(TAG, getStackTrace(e))
                   responseCode = -1;
                }

                final int code = responseCode;
                final String skus = result;
                GameActivity.queueRunnable( new Runnable() {
                  @Override public void run() {
                      onResult.call2("onSkuDetails", code, skus);
                  } } );
             } } );
    }

    public static void billingConsume(String purchaseToken)
    {
       activity.mBillingManager.consumeAsync(purchaseToken);
    }
    public static int billingClientClode()
    {
       return activity.mBillingManager.getBillingClientResponseCode();
    }
    ::end::


   public void createStageVideoSync(HaxeObject inHandler)
   {
      if (mVideoView==null)
      {
         mView.setTranslucent(true);
         mVideoView = new NMEVideoView(this,inHandler);

         RelativeLayout.LayoutParams videoLayout = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);
         videoLayout.addRule(RelativeLayout.CENTER_IN_PARENT, RelativeLayout.TRUE);

         mContainer.addView( mVideoView, 0, videoLayout );
      }
   }

   public void setVideoViewport(double inX, double inY, double inW, double inH)
   {
      //Log.d(TAG, "setVideoViewport " + inX + " " + inY + " " + inW + " " + inH);
      if ( !videoVpSet || videoX!=(int)inX || videoY!=(int)inY || videoW!=(int)inW || videoH!=(int)inH)
      {
         videoVpSet = true;
         videoX = (int)inX;
         videoY = (int)inY;
         videoW = (int)inW;
         videoH = (int)inH;
         setVideoLayout();
      }
   }

   public void setVideoLayout()
   {
      // Center within view or specified viewport
      if (mVideoView!=null)
      {
         int vidW = mVideoView.videoWidth;
         int vidH = mVideoView.videoHeight;

         if (vidW<1 || vidH<1)
         {
            RelativeLayout.LayoutParams videoLayout = new RelativeLayout.LayoutParams(LayoutParams.WRAP_CONTENT,LayoutParams.WRAP_CONTENT);
            videoLayout.addRule(RelativeLayout.CENTER_IN_PARENT, RelativeLayout.TRUE);
            mVideoView.setLayoutParams(videoLayout);
         }
         else
         {
            int x0 = videoVpSet ? videoX : 0;
            int y0 = videoVpSet ? videoY : 0;
            int w = videoVpSet ? videoW : mContainer.getWidth();
            int h = videoVpSet ? videoH : mContainer.getHeight();
            if (w*vidH > h*vidW)
            {
               int newW = h*vidW/vidH;
               x0 += (w-newW)/2;
               w = newW;
            }
            else
            {
               int newH = w*vidH/vidW;
               y0 += (h-newH)/2;
               h = newH;
            }

            int x1 = mContainer.getWidth() - x0 - w;
            int y1 = mContainer.getHeight() - y0 - h;

            RelativeLayout.LayoutParams videoLayout = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);
            //videoLayout.addRule(RelativeLayout.CENTER_IN_PARENT, RelativeLayout.TRUE);
            //Log.d(TAG, "setMargins " + x0 + " " + y0 + " " + x1 + " " + y1);
            videoLayout.setMargins(x0,y0,x1,y1);
            mVideoView.setLayoutParams( videoLayout );
         }
         mVideoView.requestLayout();
      }
   }

   public static void createStageVideo(final HaxeObject inHandler)
   {
      final GameActivity a = activity;
      queueRunnable( new Runnable() { @Override public void run() {
          a.createStageVideoSync(inHandler);
         } });
   }

   public void onResizeAsync(int width, int height)
   {
      final GameActivity me = this;
      queueRunnable( new Runnable() { @Override public void run() {
          me.setVideoLayout();
         } });
   }

   /*
   void applyTranslucent(boolean inTrans)
   {
      if (mView!=null)
         mContainer.removeView(mView);

      if (mVideoView!=null)
         mContainer.removeView(mVideoView);

     mView.setTranslucent(inTrans);

     if (mView!=null)
        mContainer.addView(mView, new LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT) );

     if (mVideoView!=null)
     {
        RelativeLayout.LayoutParams videoLayout = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);

        videoLayout.addRule(RelativeLayout.CENTER_IN_PARENT, RelativeLayout.TRUE);
        mContainer.addView( mVideoView, 0, videoLayout );
     }

     ::if !(ANDROIDVIEW)::
     setContentView(mContainer);
     ::end::

   }
   */


   public void setBackgroundSync(int inVal)
   {
      mBackground = inVal;
      boolean trans = (mBackground&0xff000000)==0 || mVideoView!=null;
      if (trans!=mView.translucent)
         mView.setTranslucent(trans);
         //applyTranslucent(trans);
   }

   public static void setBackground(final int inVal)
   {
      final GameActivity a = activity;
      queueRunnable( new Runnable() { @Override public void run() {
          a.setBackgroundSync(inVal);
         } });
   }
   
// IMMERSIVE MODE SUPPORT
::if (WIN_FULLSCREEN)::::if (ANDROID_TARGET_SDK_VERSION >= 19)::
  @Override
  public void onWindowFocusChanged(boolean hasFocus) {
    super.onWindowFocusChanged(hasFocus);
    if(hasFocus) {
      hideSystemUi();
    }
  }

  private void hideSystemUi() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      View decorView = this.getWindow().getDecorView();
      decorView.setSystemUiVisibility(
        View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
        | View.SYSTEM_UI_FLAG_FULLSCREEN
        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }
  }
::end::::end::
   
   public static double CapabilitiesGetPixelAspectRatio()
   {
      return metrics.xdpi / metrics.ydpi;
   }
   
 
   public static double CapabilitiesScaledDensity()
   {
      return metrics.scaledDensity;
   }

   
   public static double CapabilitiesGetScreenDPI()
   {
      return metrics.densityDpi;   
   }
   
   
   public static double CapabilitiesGetScreenResolutionX()
   {
      return metrics.widthPixels;
   }
   
   
   public static double CapabilitiesGetScreenResolutionY()
   {
      return metrics.heightPixels;
   }
   
   public static String CapabilitiesGetLanguage()
   {
      return Locale.getDefault().getLanguage();
   }
   
   
   public static void clearUserPreference(String inId)
   {
      SharedPreferences prefs = mContext.getSharedPreferences(GLOBAL_PREF_FILE, Activity.MODE_PRIVATE);
      SharedPreferences.Editor prefEditor = prefs.edit();
      prefEditor.putString(inId, "");
      prefEditor.apply();
   }
   
   public static boolean setClipboardText(String text) {
        try {
            int sdk = android.os.Build.VERSION.SDK_INT;
            if (sdk < android.os.Build.VERSION_CODES.HONEYCOMB)
                mClipboard.setText(text);
            else {
                android.content.ClipboardManager clipboard = (android.content.ClipboardManager) mClipboard;
                android.content.ClipData clip = android.content.ClipData
                    .newPlainText("label", text);
                clipboard.setPrimaryClip(clip);
            }
            return true;
        } catch (Exception e) {
            return false;
        }
   }

   public static boolean hasClipboardText() {
        int sdk = android.os.Build.VERSION.SDK_INT;
        if (sdk < android.os.Build.VERSION_CODES.HONEYCOMB)
            return mClipboard.getText() != null;
        else {
            android.content.ClipboardManager clipboard = (android.content.ClipboardManager) mClipboard;

            if (!(clipboard.hasPrimaryClip()))
                return false;

            if (!(clipboard.getPrimaryClipDescription().hasMimeType(android.content.ClipDescription.MIMETYPE_TEXT_PLAIN)))
                return false;

            android.content.ClipData.Item item = clipboard.getPrimaryClip().getItemAt(0);
                return item.getText() != null;
        }
   }

   public static String getClipboardText() {
       int sdk = android.os.Build.VERSION.SDK_INT;
       if (sdk < android.os.Build.VERSION_CODES.HONEYCOMB)
           return mClipboard.getText().toString();
       else {
           android.content.ClipboardManager clipboard = (android.content.ClipboardManager) mClipboard;

           if (!(clipboard.hasPrimaryClip()))
               return "";

           if (!(clipboard.getPrimaryClipDescription().hasMimeType(android.content.ClipDescription.MIMETYPE_TEXT_PLAIN)))
               return "";

           android.content.ClipData.Item item = clipboard.getPrimaryClip().getItemAt(0);
           return item.getText() != null ? item.getText().toString() : "";
       }
   }
   
   public void doPause()
   {
      Log.d(TAG,"====== doPause ========");
      _sound.doPause();
      popupKeyboard(0,null,0);
      mView.sendActivity(NME.DEACTIVATE);

      mView.onPause();

      if (mVideoView!=null)
         mVideoView.nmeSuspend();
      
      if (sensorManager != null)
      {
         sensorManager.unregisterListener(this);
      }
   }
   
   public void doResume()
   {   
      Log.d(TAG,"====== doResume ======== " + mView );
      if (mView!=null)
      {
         mView.setZOrderMediaOverlay(true);
         mView.onResume();
         mView.sendActivity(NME.ACTIVATE);
      }
      
      if (_sound!=null)
         _sound.doResume();

      if (mVideoView!=null)
      {
         // Need to rebuild the container to get the video to sit under the view - odd?
         mContainer.removeView(mKeyInTextView);
         mContainer.removeView(mVideoView);
         mContainer.removeView(mView);

         mContainer.addView(mKeyInTextView);
         mContainer.addView(mView, new LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT) );
         RelativeLayout.LayoutParams videoLayout = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);
         videoLayout.addRule(RelativeLayout.CENTER_IN_PARENT, RelativeLayout.TRUE);
         mContainer.addView( mVideoView, 0, videoLayout );

         ::if !(ANDROIDVIEW)::
         setContentView(mContainer);
         ::end::

         mVideoView.nmeResume();
      }


      if (sensorManager != null)
      {
         sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
         //sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
      }
   }

   public void onNMEFinish()
   {
      ::if !(ANDROIDVIEW)::
      finish();
      ::end::
   }
   
   
   public static Context getContext()
   {
      return mContext;
   }
   
   public static GameActivity getInstance()
   {
      return activity;
   }

   ::if !ANDROIDVIEW::
   public Activity getActivity()
   {
      return this;
   }
   ::end::

   
   public static MainView getMainView()
   {
      return activity.mView;
   }

   public static void queueRunnable(java.lang.Runnable runnable)
   {
      activity.mHandler.post(runnable);
   }

   public void sendToView(java.lang.Runnable runnable)
   {
      if (mView!=null)
         mView.queueEvent(runnable);
   }


   public static AssetManager getAssetManager()
   {
      return mAssets;
   }

   public void addResultHandler(int inRequestCode, IActivityResult inHandler)
   {
      sResultHandler.put(inRequestCode, inHandler);
   }

   public void addResultHandler(int inRequestCode, final HaxeObject inHandler)
   {
      addResultHandler( inRequestCode, new IActivityResult() {
         @Override public void onActivityResult(int inCode, Intent inData)
         {
            inHandler.call2("onActivityResult", inCode, inData);
         } } );
   }
   
   @Override public void onActivityResult(int requestCode, int resultCode, Intent data)
   {
      Log.d(TAG,"onActivityResult");
      IActivityResult handler = sResultHandler.get(requestCode);
      if (handler!=null)
      {
         sResultHandler.delete(requestCode);
         handler.onActivityResult(resultCode, data);
      }
      else
         for(Extension extension : extensions)
            if (!extension.onActivityResult(requestCode, resultCode, data) )
               return;
   }
   
   public static byte[] getResource(String inResource)
   {
      try
      {
         InputStream inputStream = null;

         int id = getResourceID(inResource);
         if (id>=0)
         {
            AssetFileDescriptor fd = activity.getResources().openRawResourceFd(id);
            inputStream = fd.createInputStream();
         }
         else
            inputStream = mAssets.open(inResource, AssetManager.ACCESS_BUFFER);

         long length = inputStream.available();
         byte[] result = new byte[(int) length];
         inputStream.read(result);
         inputStream.close();
         return result;
      }
      catch (java.io.IOException e)
      {
         Log.e(TAG,  "getResource" + ":" + e.toString());
      }
      
      return null;
   }
 
    
   public static int getResourceID(String inFilename)
   {
      ::foreach assets::::if (isSound)::::if (!embed)::if (inFilename.equals("::id::")) return ::APP_PACKAGE::.R.raw.::flatName::;
      ::end::::end::::end::
      ::foreach assets::::if (isMusic)::::if (!embed)::if (inFilename.equals("::id::")) return ::APP_PACKAGE::.R.raw.::flatName::;
      ::end::::end::::end::
      return -1;
   }
   
   
   static public String getSpecialDir(int inWhich)
    {
      Log.v(TAG,"Get special Dir " + inWhich);
      File path = null;
      
      switch (inWhich)
      {
         case 0: // App
            return mContext.getPackageCodePath();
         
         case 1: // Storage
            path = mContext.getFilesDir();
            break;
         
         case 2: // Desktop
            path = Environment.getDataDirectory();
            break;
         
         case 3: // Docs
            path = Environment.getExternalStorageDirectory();
            break;
         
         case 4: // User
            path = mContext.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
            break;
      }
      
      return path == null ? "" : path.getAbsolutePath();
   }
   
   
   public static String getUserPreference(String inId)
   {
      SharedPreferences prefs = mContext.getSharedPreferences(GLOBAL_PREF_FILE, Activity.MODE_PRIVATE);
      return prefs.getString(inId, "");
   }

   
   
   public static void launchBrowser(String inURL)
   {
      Intent browserIntent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse(inURL));
      
      try
      {
         mContext.startActivity(browserIntent);
      }
      catch (Exception e)
      {
         Log.e(TAG, e.toString());
         return;
      }
   }
   
   
   private void loadNewSensorData(SensorEvent event)
   {
      final int type = event.sensor.getType();
      
      if (type == Sensor.TYPE_ACCELEROMETER)
      {
         accelData[0] = event.values[0];
         accelData[1] = event.values[1];
         accelData[2] = event.values[2];
         // Store value in NME
         NME.onAccelerate(-accelData[0], -accelData[1], accelData[2]);
      }
      
      if (type == Sensor.TYPE_MAGNETIC_FIELD)
      {
         // this should not be done on the gui thread
         //magnetData = event.values.clone();
         //Log.d("GameActivity","new mag: " + magnetData[0] + ", " + magnetData[1] + ", " + magnetData[2]);
      }
   }
   
   
   @Override public void onAccuracyChanged(Sensor sensor, int accuracy)
   {
      
   }

   public void addOnDestoryListener(Runnable listener)
   {
      if (mOnDestroyListeners==null)
        mOnDestroyListeners = new ArrayList<Runnable>();
      mOnDestroyListeners.add(listener);
   }
   
   
   @Override public void onDestroy()
   {
      // TODO: Wait for result?
      Log.i(TAG,"onDestroy");
      if (mOnDestroyListeners!=null)
         for(Runnable listener : mOnDestroyListeners)
            listener.run();

      for(Extension extension : extensions)
         extension.onDestroy();
      mOnDestroyListeners = null;
      mView.sendActivity(NME.DESTROY);
      if (mVideoView!=null)
         mVideoView.stopPlayback();
      activity = null;
      super.onDestroy();
   }

   @Override public void onLowMemory()
   {
      super.onLowMemory ();
      for(Extension extension : extensions)
         extension.onLowMemory();
   }


   @Override protected void onNewIntent(final Intent intent)
   {
      Log.d(TAG,"onNewIntent");
      for(Extension extension : extensions)
         extension.onNewIntent(intent);
      super.onNewIntent (intent);
   }


   @Override public void onPause()
   {
      doPause();
      for(Extension extension : extensions)
         extension.onPause();
      super.onPause();
   }

   @Override public void onRestart()
   {
      super.onRestart();
      for(Extension extension : extensions)
         extension.onRestart();
   }


   @Override public void onResume()
   {
      doResume();
      Log.d(TAG,"super resume");
      super.onResume();
      for(Extension extension : extensions)
         extension.onResume();
   }

   @Override protected void onStart()
   {
      super.onStart();

      ::if WIN_FULLSCREEN::
      ::if (ANDROID_TARGET_SDK_VERSION >= 19)::
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
            View.SYSTEM_UI_FLAG_FULLSCREEN |
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );
      }
      ::elseif (ANDROID_TARGET_SDK_VERSION >= 16)::
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
            View.SYSTEM_UI_FLAG_LOW_PROFILE |
            View.SYSTEM_UI_FLAG_FULLSCREEN
        );
      }
      ::end::
      ::end::

      for(Extension extension : extensions)
        extension.onStart();
        
      Uri link = getIntentAppLink();
      if(link != null)
        NME.onAppLink(link.toString());
   }

   @Override protected void onStop ()
   {
      Log.i(TAG,"onStop");
      super.onStop ();

      for(Extension extension : extensions)
         extension.onStop();

      //https://developer.android.com/reference/android/opengl/GLSurfaceView.html#onPause()
      mView.onPause();
   }

   @Override public void onBackPressed()
   {
      Log.d(TAG,"onBackPressed");

      if (mView != null)
      {
         mView.queueEvent(new Runnable()
         {
            public void run()
            {
               mView.HandleResult(NME.onKeyChange(27, 27, true, false));
               mView.HandleResult(NME.onKeyChange(27, 27, false, false));
            }
         });
      }
   }

   public static void registerExtension(Extension extension)
   {
      if (extensions.indexOf(extension) == -1)
         extensions.add(extension);
   }


   ::if (ANDROID_TARGET_SDK_VERSION >= 14)::
   @Override public void onTrimMemory(int level)
   {
      if (Build.VERSION.SDK_INT >= 14)
      {
         super.onTrimMemory(level);
         for (Extension extension : extensions)
            extension.onTrimMemory(level);
      }
   }
   ::end::


   
   @Override public void onSensorChanged(SensorEvent event)
   {
      loadNewSensorData(event);
      // this should not be done on the gui thread
      //NME.onDeviceOrientationUpdate(prepareDeviceOrientation());
   }

  
   
   public static void postUICallback(final long inHandle)
   {
      activity.mHandler.post(new Runnable()
      {
         @Override public void run()
         {
            NME.onCallback(inHandle);
         }
      });
   }
   
   
   private int prepareDeviceOrientation()
   {
      int rawOrientation = mContext.getWindowManager().getDefaultDisplay().getOrientation();
      
      if (rawOrientation != bufferedDisplayOrientation)
      {
         bufferedDisplayOrientation = rawOrientation;
      }
      
      int screenOrientation = getResources().getConfiguration().orientation;
      int deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
      
      if (bufferedNormalOrientation < 0)
      {
         switch (screenOrientation)
         {
            case Configuration.ORIENTATION_LANDSCAPE:
               switch (bufferedDisplayOrientation)
               {
                  case DEVICE_ROTATION_0:
                  case DEVICE_ROTATION_180:
                     bufferedNormalOrientation = DEVICE_ORIENTATION_LANDSCAPE_LEFT;
                     break;
                  
                  case DEVICE_ROTATION_90:
                  case DEVICE_ROTATION_270:
                     bufferedNormalOrientation = DEVICE_ORIENTATION_PORTRAIT;
                     break;
                  
                  default:
                     bufferedNormalOrientation = DEVICE_ORIENTATION_UNKNOWN;
               }
               break;
            
            case Configuration.ORIENTATION_PORTRAIT:
               switch (bufferedDisplayOrientation)
               {
                  case DEVICE_ROTATION_0:
                  case DEVICE_ROTATION_180:
                     bufferedNormalOrientation = DEVICE_ORIENTATION_PORTRAIT;
                     break;
                  
                  case DEVICE_ROTATION_90:
                  case DEVICE_ROTATION_270:
                     bufferedNormalOrientation = DEVICE_ORIENTATION_LANDSCAPE_LEFT;
                     break;
                  
                  default:
                     bufferedNormalOrientation = DEVICE_ORIENTATION_UNKNOWN;
               }
               break;
            
            default: // ORIENTATION_SQUARE OR ORIENTATION_UNDEFINED
               bufferedNormalOrientation = DEVICE_ORIENTATION_UNKNOWN;
         }
      }
      
      switch (screenOrientation)
      {
         case Configuration.ORIENTATION_LANDSCAPE:
            switch (bufferedDisplayOrientation)
            {
               case DEVICE_ROTATION_0:
               case DEVICE_ROTATION_270:
                  deviceOrientation = DEVICE_ORIENTATION_LANDSCAPE_LEFT;
                  break;
               
               case DEVICE_ROTATION_90:
               case DEVICE_ROTATION_180:
                  deviceOrientation = DEVICE_ORIENTATION_LANDSCAPE_RIGHT;
                  break;
               
               default: // impossible!
                  deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
            }
            break;
         
         case Configuration.ORIENTATION_PORTRAIT:
            switch (bufferedDisplayOrientation)
            {
               case DEVICE_ROTATION_0:
               case DEVICE_ROTATION_90:
                  deviceOrientation = DEVICE_ORIENTATION_PORTRAIT;
                  break;
               
               case DEVICE_ROTATION_180:
               case DEVICE_ROTATION_270:
                  deviceOrientation = DEVICE_ORIENTATION_PORTRAIT_UPSIDE_DOWN;
                  break;
               
               default: // impossible!
                  deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
            }
            break;
         
         default: // ORIENTATION_SQUARE OR ORIENTATION_UNDEFINED
            deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
      }
      
      return deviceOrientation;
   }
   
   
   ::if !(ANDROIDVIEW)::
   public static void pushView(View inView)
   {
      activity.doPause();
      activity.setContentView(inView);
   }
   public static void popView()
   {
      // mContainer?
      activity.setContentView(activity.mView);
      activity.doResume();
   }
   ::end::


   /*
      Requires
      <appPermission value="android.permission.INTERNET" />
      <appPermission value="android.permission.ACCESS_WIFI_STATE" />
   */
   public static String getLocalIpAddress()
   {
      String result = "127.0.0.1";
      try
      {
         for(Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces();
            en.hasMoreElements();)
         {
            NetworkInterface intf = en.nextElement();
            for (Enumeration<InetAddress> enumIpAddr = intf.getInetAddresses();
               enumIpAddr.hasMoreElements();)
            {
               InetAddress inetAddress = enumIpAddr.nextElement();
               //Log.e("Try local", inetAddress.getHostAddress());
               if (!inetAddress.isLoopbackAddress())
               {
                  if (inetAddress instanceof Inet4Address)
                     result = inetAddress.getHostAddress();
               }
            }
         }
      }
      catch (Exception ex)
      {
         Log.e(TAG, "Could not get local address:" + ex.toString());
      }
      return result;
   }



   public void restartProcessInst()
   {
      ::if !ANDROIDVIEW::
      AlarmManager alm = (AlarmManager)getSystemService(Context.ALARM_SERVICE);
      alm.set(AlarmManager.RTC, System.currentTimeMillis() + 1000,
          PendingIntent.getActivity(this, 0, new Intent(this, this.getClass()), 0));
      ::end::
   }

   public static void restartProcess()
   {
      activity.restartProcessInst();
   }
         
   
   public static void setUserPreference(String inId, String inPreference)
   {
      SharedPreferences prefs = mContext.getSharedPreferences(GLOBAL_PREF_FILE, Activity.MODE_PRIVATE);
      SharedPreferences.Editor prefEditor = prefs.edit();
      prefEditor.putString(inId, inPreference);
      prefEditor.apply();
   }
   
   
   public static void popupKeyboard(final int inMode, final  String inContent, final int inType)
   {
      try { 
         activity.mHandler.post(new Runnable() {
            @Override public void run() {
               try {
                  handlePopKeyboard(inMode, inContent, inType);
               }
               catch(Exception e) {
                  Log.e(TAG, getStackTrace(e));
                  Log.e(TAG,"handlePopKeyboard: " + e);
               }
            }
         });
      }
      catch(Exception e) {
        Log.e(TAG, getStackTrace(e));
        Log.e(TAG,"popupKeyboard: " + e);  
      }
   }

   private static void handlePopKeyboard(final int inMode, final  String inContent, final int inType)
   {
      InputMethodManager mgr = (InputMethodManager)mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
      mgr.hideSoftInputFromWindow(activity.mView.getWindowToken(), 0);
      
      if (inMode!=KEYBOARD_OFF)
      {
         activity.mTextUpdateLockout = true;
         activity.mIncrementalText = inContent==null;
         if (inMode==KEYBOARD_DUMB)
            activity.mView.requestFocus();
         else // todo - force native control
         {
            activity.mKeyInTextView.requestFocus();
            if (!activity.mIncrementalText)
            {
               activity.mKeyInTextView.setText(inContent);
            }
            else
            {
               activity.mKeyInTextView.setText("*");
               activity.mKeyInTextView.setSelection(1);
            }
         }

         if (inType == 1)
             activity.mKeyInTextView.setInputType(activity.mDefaultInputType | InputType.TYPE_TEXT_VARIATION_PERSON_NAME);
         else if (inType == 2)
             activity.mKeyInTextView.setInputType(activity.mDefaultInputType | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS);
         else if (inType == 5)
             activity.mKeyInTextView.setInputType(activity.mDefaultInputType | InputType.TYPE_TEXT_VARIATION_URI);
         else if (inType == 3)
             activity.mKeyInTextView.setInputType(InputType.TYPE_CLASS_NUMBER);
         else if (inType == 4)
             activity.mKeyInTextView.setInputType(activity.mDefaultInputType | InputType.TYPE_TEXT_VARIATION_PHONETIC);
         else if (inType == 101)//only on android
             activity.mKeyInTextView.setInputType(activity.mDefaultInputType | InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);
         else
             activity.mKeyInTextView.setInputType(activity.mDefaultInputType);

         mgr.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
         // On the Nexus One, SHOW_FORCED makes it impossible
         // to manually dismiss the keyboard.
         // On the Droid SHOW_IMPLICIT doesn't bring up the keyboard.
         activity.mTextUpdateLockout = false;
      }
   }

   
   public static void setPopupSelection(final int inSel0, final int inSel1)
   {
      //Log.v("VIEW","Post setPopupSelection " + (activity.mIncrementalText ?"inc ":"smart ") + inSel0 + "..." + inSel1 );
      activity.mHandler.post(new Runnable() {
         @Override public void run()
         {
            if (!activity.mIncrementalText)
            {
                activity.mTextUpdateLockout = true;
               //Log.v("VIEW","Run setPopupSelection " + (activity.mIncrementalText ?"inc ":"smart ") + inSel0 + "..." + inSel1 );
               if (inSel0!=inSel1)
                  activity.mKeyInTextView.setSelection(inSel0,inSel1);
               else {
                  int selection = calcSelectionIndex(inSel0, activity.mKeyInTextView);
                  activity.mKeyInTextView.setSelection(selection);
               }
                activity.mTextUpdateLockout = false;
            }
         }} );
   }

   private static int calcSelectionIndex(int index, EditText editText){
      if(index >= editText.getText().length())
         return 0;
      return index;
   }
        
   void onSelectionChanged(final int selStart, final int selEnd)
   {
      if (mTextUpdateLockout || mView==null || mIncrementalText)
         return;
      mView.queueEvent(new Runnable() {
         public void run() {
            if (mView==null)
               return;
            //Log.v("VIEW*","replaced " + replace + " at  " + start + " (delete =" + before + ")" );
            mView.HandleResult(NME.onTextSelect(selStart,selEnd));
        }
     });
   }
 
   void addTextListeners()
   {
        mKeyInTextView.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count,
                                          int after) {
                if(ignoreTextReset)
                   return;
                // Log.v("VIEW*","beforeTextChanged [" + s + "] " + start + " " + count + " " + after);
            }

            @Override
            public void onTextChanged(final CharSequence s, final int start, final int before, final int count)
            {
               if (mTextUpdateLockout || mView==null)
               {
                  //Log.v("VIEW*","Ignore init text " + s);
                  return;
               }
               if(ignoreTextReset)
                  return;
               //Log.v("VIEW*","onTextChanged [" + s + "] " + start + " " + before + " " + count);
               mView.queueEvent(new Runnable() {
                  public void run() {
                     if (mView==null)
                        return;
                     if (mIncrementalText)
                      {
                        for(int i = 1;i <= before;i++)
                        {
                           // This method will be called on the rendering thread:
                           mView.HandleResult(NME.onKeyChange(8, 8, true, false));
                           mView.HandleResult(NME.onKeyChange(8, 8, false, false));
                        }
                        for (int i = start; i < start + count; i++)
                        {
                           int keyCode = s.charAt(i);
                           if (keyCode != 0)
                            {
                              mView.HandleResult(NME.onKeyChange(keyCode, keyCode, true, keyCode == 10 ? false : true));
                              mView.HandleResult(NME.onKeyChange(keyCode, keyCode, false, false));
                           }
                        }
                     }
                     else
                     {
                        String replace = count==0 ? "" : s.subSequence(start,start+count).toString();
                        //Log.v("VIEW*","replaced " + replace + " at  " + start + " (delete =" + before + ")" );
                        mView.HandleResult(NME.onText(replace,start,start+before));
                     }
               } } );

               ignoreTextReset = before > 1 || count > 1 || (count == 1 && s.charAt(start) == ' ');
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (mIncrementalText)
                {
                   if(!ignoreTextReset) {
                       // Log.v("VIEW*", "afterTextChanged [" + s + "] ");
                       if (s.length() != 1) {
                           ignoreTextReset = true;
                           mKeyInTextView.setText("*");
                           mKeyInTextView.setSelection(1);
                       }
                   }
                }
                ignoreTextReset = false;
            }
        });

        
        mKeyInTextView.setOnKeyListener(new View.OnKeyListener() {
            @Override
            public boolean onKey(View v, int keyCode, KeyEvent event) {
                if (mIncrementalText && mView!=null)
                {
                //if (keyCode == KeyEvent.KEYCODE_ENTER) {
                    if(event.getAction() == KeyEvent.ACTION_DOWN) {
                        final int keyCodeDown = MainView.translateKey(keyCode,event,false);
                        if(keyCodeDown != 0) {
                            mView.queueEvent(new Runnable() {
                                // This method will be called on the rendering thread:
                                public void run() {
                                   if (mView!=null)
                                       mView.HandleResult(NME.onKeyChange(keyCodeDown, 0, true, false));
                                }
                            });
                            return true;
                        }
                    } else if(event.getAction() == KeyEvent.ACTION_UP) {
                        final int keyCodeUp = MainView.translateKey(keyCode,event,false);
                        if(keyCodeUp != 0) {
                            mView.queueEvent(new Runnable() {
                                // This method will be called on the rendering thread:
                                public void run() {
                                    if (mView!=null)
                                       mView.HandleResult(NME.onKeyChange(keyCodeUp, 0, false, false));
                                }
                            });
                            return true;
                        }
                    }
                //}
                }
                return false;
            }
        });
/*
        mKeyInTextView.getText().setSpan( new SpanWatcher() {
           @Override
           public void onSpanAdded(final Spannable text, final Object what, final int start, final int end) {
              Log.v("VIEW", "onSpanAdded");
           }

           @Override
           public void onSpanRemoved(final Spannable text, final Object what, final int start, final int end) {
              Log.v("VIEW", "onSpanRemoved"):
           }

           @Override
           public void onSpanChanged(final Spannable text, final Object what,final int ostart, final int oend, final int nstart, final int nend)
           {
              Log.v("VIEW", "onSpanChanged " + nstart + "," + nend);
           }
        }, 0, 0, Spanned.SPAN_INCLUSIVE_EXCLUSIVE);
        */
    }


   
   
   public static void vibrate(int period, int duration)
   {
      Vibrator v = (Vibrator)mContext.getSystemService(Context.VIBRATOR_SERVICE);
      
      if (period == 0)
      {
         v.vibrate(duration);
      }
      else
      {   
         int periodMS = (int)Math.ceil(period / 2);
         int count = (int)Math.ceil((duration / period) * 2);
         long[] pattern = new long[count];
         
         for (int i = 0; i < count; i++)
         {
            pattern[i] = periodMS;
         }
         
         v.vibrate(pattern, -1);
      }
   }

   private Uri getIntentAppLink()
   {
      Intent intent = getIntent();
      String action = intent.getAction();
      return intent.getData();
   }

   private static String getStackTrace(Exception e)
   {
      StringWriter sw = new StringWriter();
      PrintWriter pw = new PrintWriter(sw);
      e.printStackTrace(pw);
      return sw.toString();
   }
}


