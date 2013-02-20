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
import android.content.Context;
import android.media.SoundPool;
import android.media.MediaPlayer;
import android.net.Uri;
import android.util.DisplayMetrics;
import android.content.SharedPreferences;
import android.view.inputmethod.InputMethodManager;
import dalvik.system.DexClassLoader;

import java.io.File;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.lang.reflect.Constructor;

public class GameActivity extends Activity implements SensorEventListener {

    MainView mView;
    static AssetManager mAssets;
    static SoundPool mSoundPool;
    static int       mSoundPoolID;
    static Context mContext;
    static MediaPlayer mMediaPlayer = null;
    static final String GLOBAL_PREF_FILE="nmeAppPrefs";
    static GameActivity activity;
    public android.os.Handler mHandler;
    static HashMap<String,Class> mLoadedClasses = new HashMap<String,Class>();
	static DisplayMetrics metrics;
	static SensorManager sensorManager;

    protected void onCreate(Bundle state) {
        super.onCreate(state);
        activity=this;
        mContext = this;
        mHandler = new android.os.Handler();
        mAssets = getAssets();
        setVolumeControlStream(android.media.AudioManager.STREAM_MUSIC);  

        mSoundPoolID = 1;
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

       ::foreach assets::
       ::if (type=="sound")::
          if (inFilename.equals("::id::"))
             id = ::APP_PACKAGE::.R.raw.::flatName::;
          ::end::
       ::end::

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

       ::foreach assets::
       ::if (type=="music")::
          if (inFilename.equals("::id::"))
             id = ::APP_PACKAGE::.R.raw.::flatName::;
          ::end::
       ::end::

       Log.v("GameActivity","Got music handle ------" + id);

       return id;
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

    static public int playMusic(int inResourceID, double inVolLeft, double inVolRight, int inLoop)
    {
       Log.v("GameActivity","playMusic -----" + inResourceID);
       if (mMediaPlayer!=null)
       {
          Log.v("GameActivity","stop MediaPlayer");
          mMediaPlayer.stop();
          mMediaPlayer = null;
       }
    
       mMediaPlayer = MediaPlayer.create(mContext, inResourceID);
       if (mMediaPlayer==null)
           return -1;

       mMediaPlayer.setVolume((float)inVolLeft,(float)inVolRight);
       if (inLoop<0)
          mMediaPlayer.setLooping(true);
       else if (inLoop>0)
       {
       }
       mMediaPlayer.start();

       return 0;
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
        mSoundPool = null;
        mView.sendActivity(NME.DEACTIVATE);
        mView.onPause();
        if (mMediaPlayer!=null)
           mMediaPlayer.pause();
           
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
        if (mMediaPlayer!=null)
           mMediaPlayer.start();
        mView.sendActivity(NME.ACTIVATE);
        
		if (sensorManager != null) {
			sensorManager.registerListener(this, 
				sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
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
        if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
        	float[] values = event.values;
        	NME.onAccelerate(values[0], values[1], values[2]);
        }
   }
   
   @Override public void onAccuracyChanged(Sensor sensor, int accuracy) {
   
   }
}

