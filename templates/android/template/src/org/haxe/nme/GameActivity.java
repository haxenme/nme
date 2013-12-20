package org.haxe.nme;


import android.app.Activity;
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
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.Math;
import java.util.HashMap;
import java.util.Locale;

::if ANDROIDVIEW::
import android.app.Fragment;
::end::

public class GameActivity extends
::if ANDROIDVIEW::
Fragment
::else::
Activity
::end::
implements SensorEventListener
{
   static final String TAG = "GameActivity";

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
   
   public Handler mHandler;
   RelativeLayout mContainer;
   int            mBackground;
   MainView       mView;

   boolean        videoVpSet = false;
   int            videoX = 0;
   int            videoY = 0;
   int            videoW = 0;
   int            videoH = 0;

   
   private static float[] accelData = new float[3];
   private static int bufferedDisplayOrientation = -1;
   private static int bufferedNormalOrientation = -1;
   private static float[] inclinationMatrix = new float[16];
   private static float[] magnetData = new float[3];
   private static float[] orientData = new float[3];
   private static float[] rotationMatrix = new float[16];
   private Sound _sound;
   
   public NMEVideoView   mVideoView;


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
      mBackground = 0;
      
      //getResources().getAssets();
      
      metrics = new DisplayMetrics();
      mContext.getWindowManager().getDefaultDisplay().getMetrics(metrics);
      
      // Pre-load these, so the C++ knows where to find them
      
      ::foreach ndlls::
      System.loadLibrary("::name::");::end::
      org.haxe.HXCPP.run("ApplicationMain");
      

      mContainer = new RelativeLayout(mContext);

      mView = new MainView(mContext, this, false);

      mContainer.addView(mView, new LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT) );

      
      /*
       weak ref instances?
      sensorManager = (SensorManager)mContext.getSystemService(Context.SENSOR_SERVICE);
      
      if (sensorManager != null)
      {
         sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
         sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
      }
      */


      ::if !(ANDROIDVIEW)::
      setContentView(mContainer);
      ::end::
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

   public void setBackgroundSync(int inVal)
   {
      mBackground = inVal;
      //Log.d(TAG,"Set background " + inVal);
   }

   public static void setBackground(final int inVal)
   {
      final GameActivity a = activity;
      queueRunnable( new Runnable() { @Override public void run() {
          a.setBackgroundSync(inVal);
         } });
   }
   
   
   public static double CapabilitiesGetPixelAspectRatio()
   {
      return metrics.xdpi / metrics.ydpi;
   }
   
   
   public static double CapabilitiesGetScreenDPI()
   {
      return metrics.xdpi;   
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
      prefEditor.commit();
   }
   
   
   public void doPause()
   {
      Log.d(TAG,"====== doPause ========");
      _sound.doPause();

      mView.sendActivity(NME.DEACTIVATE);

      mView.onPause();

      if (mVideoView!=null)
         mVideoView.nmeSuspend();
      
      /*
      if (sensorManager != null)
      {
         sensorManager.unregisterListener(this);
      }
      */
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
         mContainer.removeView(mVideoView);
         mContainer.removeView(mView);

         mContainer.addView(mView, new LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT) );
         RelativeLayout.LayoutParams videoLayout = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT,LayoutParams.FILL_PARENT);
         videoLayout.addRule(RelativeLayout.CENTER_IN_PARENT, RelativeLayout.TRUE);
         mContainer.addView( mVideoView, 0, videoLayout );

         ::if !(ANDROIDVIEW)::
         setContentView(mContainer);
         ::end::

         mVideoView.nmeResume();
      }


      /*
      if (sensorManager != null)
      {
         sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
         sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
      }
      */
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
   
   
   public static byte[] getResource(String inResource)
   {
      try
      {
         InputStream inputStream = mAssets.open(inResource, AssetManager.ACCESS_BUFFER);
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
      ::foreach assets::::if (type == "music")::if (inFilename.equals("::id::")) return ::APP_PACKAGE::.R.raw.::flatName::;
      ::end::::end::
      ::foreach assets::::if (type == "sound")::if (inFilename.equals("::id::")) return ::APP_PACKAGE::.R.raw.::flatName::;
      ::end::::end::
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
         // this should not be done on the gui thread
         //accelData = event.values.clone();
         //NME.onAccelerate(-accelData[0], -accelData[1], accelData[2]);
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
   
   
   @Override public void onDestroy()
   {
      // TODO: Wait for result?
      Log.d(TAG,"onDestroy");
      mView.sendActivity(NME.DESTROY);
      if (mVideoView!=null)
         mVideoView.stopPlayback();
      activity = null;
      super.onDestroy();
   }
   
   
   @Override public void onPause()
   {
      doPause();
      super.onPause();
   }
   
   
   @Override public void onResume()
   {
      doResume();
      Log.d(TAG,"super resume");
      super.onResume();
   }
   
   @Override public void onSensorChanged(SensorEvent event)
   {
      loadNewSensorData(event);
      
      ::if !(ANDROIDVIEW)::
      if (accelData != null && magnetData != null)
      {
         boolean foundRotationMatrix = SensorManager.getRotationMatrix(rotationMatrix, inclinationMatrix, accelData, magnetData);
         if (foundRotationMatrix)
         {
            SensorManager.getOrientation(rotationMatrix, orientData);
            // this should not be done on the gui thread
            // NME.onOrientationUpdate(orientData[0], orientData[1], orientData[2]);
         }
      }
      
      // this should not be done on the gui thread
      //NME.onDeviceOrientationUpdate(prepareDeviceOrientation());
      //NME.onNormalOrientationFound(bufferedNormalOrientation);
      ::end::
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
      activity.setContentView(activity.mView);
      activity.doResume();
   }
   ::end::
   
   
   public static void setUserPreference(String inId, String inPreference)
   {
      SharedPreferences prefs = mContext.getSharedPreferences(GLOBAL_PREF_FILE, Activity.MODE_PRIVATE);
      SharedPreferences.Editor prefEditor = prefs.edit();
      prefEditor.putString(inId, inPreference);
      prefEditor.commit();
   }
   
   
   public static void showKeyboard(boolean show)
   {
      InputMethodManager mgr = (InputMethodManager)mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
      mgr.hideSoftInputFromWindow(activity.mView.getWindowToken(), 0);
      
      if (show)
      {
         mgr.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
         // On the Nexus One, SHOW_FORCED makes it impossible
         // to manually dismiss the keyboard.
         // On the Droid SHOW_IMPLICIT doesn't bring up the keyboard.
      }
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
}



