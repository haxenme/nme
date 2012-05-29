package org.haxe.nme;


import android.app.Activity;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.view.Window;
import android.view.View;
import android.util.Log;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;
import android.content.res.Configuration;
import android.content.Context;
import android.media.SoundPool;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.content.SharedPreferences;
import android.view.inputmethod.InputMethodManager;
import dalvik.system.DexClassLoader;

import java.io.File;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.lang.Math;
import java.lang.reflect.Constructor;

public class GameActivity extends Activity implements SensorEventListener {
    private static final int DEVICE_ORIENTATION_UNKNOWN			= 0;
    private static final int DEVICE_ORIENTATION_PORTRAIT		= 1;
    private static final int DEVICE_ORIENTATION_PORTRAIT_UPSIDE_DOWN	= 2;
    private static final int DEVICE_ORIENTATION_LANDSCAPE_RIGHT		= 3;
    private static final int DEVICE_ORIENTATION_LANDSCAPE_LEFT		= 4;
    private static final int DEVICE_ORIENTATION_FACE_UP			= 5;
    private static final int DEVICE_ORIENTATION_FACE_DOWN		= 6;

    private static final int DEVICE_ROTATION_0				= 0;
    private static final int DEVICE_ROTATION_90				= 1;
    private static final int DEVICE_ROTATION_180			= 2;
    private static final int DEVICE_ROTATION_270			= 3;

    MainView mView;
    static AssetManager mAssets;
    static SoundPool mSoundPool;
    static int       mSoundPoolID=0;
    static Context mContext;
    static MediaPlayer mMediaPlayer = null;
	static boolean mMusicComplete = true;
	static boolean mMusicWasPlaying = false;
	static int mMusicLoopsLeft = 0;
    static final String GLOBAL_PREF_FILE="nmeAppPrefs";
    static GameActivity activity;
    public android.os.Handler mHandler;
    static HashMap<String,Class> mLoadedClasses = new HashMap<String,Class>();
	static DisplayMetrics metrics;
	static SensorManager sensorManager;

    private static float[] rotationMatrix = new float[16];
    private static float[] inclinationMatrix = new float[16];
    private static float[] accelData = new float[3];
    private static float[] magnetData = new float[3];
    private static float[] orientData = new float[3];
    private static int bufferedDisplayOrientation = -1;
    private static int bufferedNormalOrientation = -1;


    protected void onCreate(Bundle state) {
        super.onCreate(state);
        activity=this;
        mContext = this;
        mHandler = new android.os.Handler();
        mAssets = getAssets();

		if(mSoundPoolID>1)
		{
			mSoundPoolID++;
		}
        else
		{
			mSoundPoolID = 1;
		}
        mSoundPool = new SoundPool(8,android.media.AudioManager.STREAM_MUSIC,0);
       //getResources().getAssets();

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, 
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
		
		metrics = new DisplayMetrics ();
		getWindowManager().getDefaultDisplay().getMetrics (metrics);
		
        // Pre-load these, so the c++ knows where to find them
        ::foreach ndlls::
           System.loadLibrary("::name::");
         ::end::
        org.haxe.HXCPP.run("ApplicationMain");

        mView = new MainView(getApplication(),this);

        setContentView(mView);
		
		sensorManager = (SensorManager)
			activity.getSystemService(Context.SENSOR_SERVICE);
		if (sensorManager != null) {
			sensorManager.registerListener(this, 
				sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
				SensorManager.SENSOR_DELAY_GAME);
			sensorManager.registerListener(this, 
				sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD),
				SensorManager.SENSOR_DELAY_GAME);
		}
    }

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


    public static GameActivity getInstance() { return activity; }

    public static void showKeyboard(boolean show) 
    {
        InputMethodManager mgr = (InputMethodManager)
           activity.getSystemService(Context.INPUT_METHOD_SERVICE);

        mgr.hideSoftInputFromWindow(activity.mView.getWindowToken(), 0);
        if (show) {
            mgr.toggleSoftInput(InputMethodManager.SHOW_FORCED,0);
            // On the Nexus One, SHOW_FORCED makes it impossible
            // to manually dismiss the keyboard.
            // On the Droid SHOW_IMPLICIT doesn't bring up the keyboard.
        }
    }

    static public byte [] getResource(String inResource) {

           //Log.e("GameActivity","Get resource------------------>" + inResource);
           try {
                  java.io.InputStream inputStream = mAssets.open(inResource,AssetManager.ACCESS_BUFFER);
                  long length = inputStream.available();
                  byte[] result = new byte[(int) length];
                  inputStream.read(result);
                  inputStream.close();
                  return result;
           } catch (java.io.IOException e) {
               Log.e("GameActivity",  "getResource" + ":" + e.toString());
           }

           return null;
    }

    static public int getSoundHandle(String inFilename)
    {
       int id = -1;
       
       ::foreach assets::::if (type=="sound")::if (inFilename.equals("::id::")) id = ::APP_PACKAGE::.R.raw.::flatName::;
	   ::end::::end::
       
       Log.v("GameActivity","Get sound handle ------" + inFilename + " = " + id);
       if (id>0)
       {
          int index = mSoundPool.load(mContext,id,1);
          Log.v("GameActivity","Loaded index" + index);
          return index;
       }
       else
          Log.v("GameActivity","Resource not found" + (-id) );
       
       return -1;
    }
    
    static public int getMusicHandle(String inFilename)
    {
       int id = -1;
       Log.v("GameActivity","Get music handle ------" + inFilename);
       
       ::foreach assets::::if (type=="music")::if (inFilename.equals("::id::")) id = ::APP_PACKAGE::.R.raw.::flatName::;
       ::end::::end::
       
       Log.v("GameActivity","Got music handle ------" + id);
       
       return id;
    }
	
	static public boolean getMusicComplete()
	{
		return mMusicComplete;
	}
	
	static public int getSoundLength(int inResourceID)
	{
		MediaPlayer mp = MediaPlayer.create(mContext, inResourceID);
		if (mp == null)
			return -1;
		return mp.getDuration();
	}

    static public int getSoundPoolID() { return mSoundPoolID; }

    static public Context getContext() { return mContext; }

    static public String getSpecialDir(int inWhich)
    {
       Log.v("GameActivity","Get special Dir " + inWhich);
       File path = null;
       switch(inWhich)
       {
          case 0: // App
              return mContext.getPackageCodePath();
          case 1: // Storage
              path = mContext.getFilesDir();
              break;
          case 2: // Desktop
             path = android.os.Environment.getDataDirectory();
             break;
          case 3: // Docs
             path =android.os.Environment.getExternalStorageDirectory();
             break;
          case 4: // User
             path = mContext.getExternalFilesDir(android.os.Environment.DIRECTORY_DOWNLOADS);
              break;
       }
       return path==null ? "" : path.getAbsolutePath();
    }

    static public int playSound(int inSoundID, double inVolLeft, double inVolRight, int inLoop)
    {
       Log.v("GameActivity","PlaySound -----" + inSoundID);
       return mSoundPool.play(inSoundID,(float)inVolLeft,(float)inVolRight, 1, inLoop, 1.0f);
    }

    static public int playMusic(int inResourceID, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
       if (mMediaPlayer!=null)
       {
          Log.v("GameActivity","stop MediaPlayer");
          mMediaPlayer.stop();
          mMediaPlayer = null;
       }
	   
	   mMusicComplete = false;
    
       mMediaPlayer = MediaPlayer.create(mContext, inResourceID);
       if (mMediaPlayer==null)
           return -1;

       mMediaPlayer.setVolume((float)inVolLeft,(float)inVolRight);
       if (inLoop<0)
	   {
          mMediaPlayer.setLooping(true);
	   }
       else if (inLoop>=0)
       {
	      mMusicLoopsLeft = inLoop;
		  mMediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
			  @Override public void onCompletion( MediaPlayer mp ) {
				  if (--mMusicLoopsLeft > 0)
				  {
					  mp.seekTo(0);
					  mp.start();
				  }
				  else
				  {
					  mMusicComplete = true;
				  }
			  }
		  });
       }
	   mMediaPlayer.seekTo((int)inStartTime);
       mMediaPlayer.start();

       return 0;
    }
	
	static public void setMusicTransform(double inVolLeft, double inVolRight)
	{
		if(mMediaPlayer==null)
		{
			return;
		}
		
		mMediaPlayer.setVolume((float)inVolLeft,(float)inVolRight);
	}
	
	static public void stopSound(int inStreamID) {
		if (mSoundPool != null)
			mSoundPool.stop (inStreamID);
	}
    
    static public void stopMusic() {
		Log.v("GameActivity","stop MediaPlayer");
		if (mMediaPlayer != null)
			mMediaPlayer.stop();
	}

    static public void postUICallback(final long inHandle)
    {
       activity.mHandler.post(new Runnable() {
         @Override public void run() {
                NME.onCallback(inHandle); } });
    }
	
	static public void vibrate(int period, int duration)
	{
		Vibrator v = (Vibrator)activity.getSystemService(Context.VIBRATOR_SERVICE);
		
		if (period == 0)
		{
			v.vibrate(duration);
		}
		else
		{	
			int periodMS = (int) Math.ceil (period / 2);
			int count = (int) Math.ceil ((duration / period) * 2);
			long[] pattern = new long[count];
			
			for (int i = 0; i < count; i++)
			{
				pattern[i] = periodMS;
			}
			
			v.vibrate (pattern, -1);
		}
	}

    static public void launchBrowser(String inURL)
    {
      Intent browserIntent=new Intent(Intent.ACTION_VIEW).setData(Uri.parse(inURL));
      try
      {
         activity.startActivity(browserIntent);
      }
      catch (Exception e)
      {
         Log.e("GameActivity",e.toString());
         return;
      }

    }
	
	static public double CapabilitiesGetPixelAspectRatio () {
		
		return metrics.xdpi / metrics.ydpi;
		
	}
	
	static public double CapabilitiesGetScreenDPI () {
		
		return metrics.xdpi;
		
	}
	
	static public double CapabilitiesGetScreenResolutionX () {
		
		return metrics.widthPixels;
		
	}
	
	static public double CapabilitiesGetScreenResolutionY () {
		
		return metrics.heightPixels;
		
	}
    
    static public String getUserPreference(String inId)
    {
      SharedPreferences prefs = activity.getSharedPreferences(GLOBAL_PREF_FILE,MODE_PRIVATE);
      return prefs.getString(inId,"");
    }
    
    static public void setUserPreference(String inId, String inPreference)
    {
      SharedPreferences prefs = activity.getSharedPreferences(GLOBAL_PREF_FILE,MODE_PRIVATE);
      SharedPreferences.Editor prefEditor = prefs.edit();
      prefEditor.putString(inId,inPreference);
      prefEditor.commit();
    }
    
    static public void clearUserPreference(String inId)
    {
      SharedPreferences prefs = activity.getSharedPreferences(GLOBAL_PREF_FILE,MODE_PRIVATE);
      SharedPreferences.Editor prefEditor = prefs.edit();
      prefEditor.putString(inId,"");
      prefEditor.commit();
    }
    

    static public void playMusic(String inFilename)
    {
    }

    @Override protected void onPause() {
        super.onPause();
        doPause();
    }

    public void doPause() {
		if(mSoundPool!=null)
		{
			mSoundPool.release();
		}
        mSoundPool = null;
        mView.sendActivity(NME.DEACTIVATE);
        mView.onPause();
        if (mMediaPlayer!=null) {
			mMusicWasPlaying = mMediaPlayer.isPlaying();
            mMediaPlayer.pause();
		}
           
        if (sensorManager != null) 
        	sensorManager.unregisterListener(this);
    }

    @Override protected void onResume() {
        super.onResume();
        doResume();
     }

    public void doResume() {
        mSoundPoolID++;
        mSoundPool = new SoundPool(8,android.media.AudioManager.STREAM_MUSIC,0);
        mView.onResume();
        if (mMediaPlayer!=null) {
			if (mMusicWasPlaying) {
				mMediaPlayer.start();
			}
		}
        mView.sendActivity(NME.ACTIVATE);
        
		if (sensorManager != null) {
			sensorManager.registerListener(this, 
				sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
				SensorManager.SENSOR_DELAY_GAME);
			sensorManager.registerListener(this, 
				sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD),
				SensorManager.SENSOR_DELAY_GAME);
		}
    }
   
   @Override protected void onDestroy() {
      // TODO: Wait for result?
      mView.sendActivity(NME.DESTROY);
      activity=null;
      super.onDestroy();
   }
   
   @Override public void onSensorChanged(SensorEvent event) {
      // use this if you want to test sensor reliability before using the signal.
      // I have found through experience if I try to use this, I never get an accelerometer
      // signal :). As a result, it is not used.
      /*if (event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE) {
         Log.d("GameActivity","unreliable..");
         return;
      }*/

      loadNewSensorData(event);

      // if sensor values are valid, then find rotation matrix.
      // this is necessary because Android coordinate system adjusts per orientation.
      if (accelData != null) {
         if (magnetData != null) {
            // check that the rotation matrix is found before use
            boolean success = SensorManager.getRotationMatrix(rotationMatrix, inclinationMatrix,
                                                          accelData, magnetData);
            if (success) {
               SensorManager.getOrientation(rotationMatrix, orientData);
               NME.onOrientationUpdate(orientData[0], orientData[1], orientData[2]);
               //Log.d("GameActivity","\n >> new orient: " + Math.toDegrees(orientData[0]) + ", " + Math.toDegrees(orientData[1]) + ", " + Math.toDegrees(orientData[2]));
            }
         }

         //setRequestedOrientation(android.content.pm.ActivityInfo.SCREEN_ORIENTATION_USER);
      }         
      NME.onDeviceOrientationUpdate(prepareDeviceOrientation());
      NME.onNormalOrientationFound(bufferedNormalOrientation);
   }

   private void loadNewSensorData(SensorEvent event) {
      final int type = event.sensor.getType();
      if (type == Sensor.TYPE_ACCELEROMETER) {
         accelData = event.values.clone();
         NME.onAccelerate(accelData[0], accelData[1], accelData[2]);
      }
      if (type == Sensor.TYPE_MAGNETIC_FIELD) {
         magnetData = event.values.clone();
         //Log.d("GameActivity","new mag: " + magnetData[0] + ", " + magnetData[1] + ", " + magnetData[2]);
      }
   }

   private int prepareDeviceOrientation() {
      int rawOrientation = getWindow().getWindowManager().getDefaultDisplay().getOrientation();
      if (rawOrientation != bufferedDisplayOrientation) {
         bufferedDisplayOrientation = rawOrientation;
      }

      int screenOrientation = getResources().getConfiguration().orientation;
      int deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;

      if (bufferedNormalOrientation < 0) {
         switch (screenOrientation) {
            case Configuration.ORIENTATION_LANDSCAPE:
               switch(bufferedDisplayOrientation) {
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
               switch(bufferedDisplayOrientation) {
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
      switch (screenOrientation) {
         case Configuration.ORIENTATION_LANDSCAPE:
            switch(bufferedDisplayOrientation) {
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
            switch(bufferedDisplayOrientation) {
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
   
   @Override public void onAccuracyChanged(Sensor sensor, int accuracy) {
   
   }
}

