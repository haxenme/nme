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
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.Math;
import java.util.HashMap;


public class GameActivity extends Activity implements SensorEventListener
{
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
	
	static GameActivity activity;
	static AssetManager mAssets;
	static Context mContext;
	static DisplayMetrics metrics;
	static HashMap<String, Class> mLoadedClasses = new HashMap<String, Class>();
	static MediaPlayer mMediaPlayer = null;
	static boolean mMusicComplete = true;
	static int mMusicLoopsLeft = 0;
	static boolean mMusicWasPlaying = false;
	static SoundPool mSoundPool;
	static int mSoundPoolID = 0;
	static SensorManager sensorManager;
	
	public Handler mHandler;
	MainView mView;
	
	private static float[] accelData = new float[3];
	private static int bufferedDisplayOrientation = -1;
	private static int bufferedNormalOrientation = -1;
	private static float[] inclinationMatrix = new float[16];
	private static float[] magnetData = new float[3];
	private static float[] orientData = new float[3];
	private static float[] rotationMatrix = new float[16];
	
	
	protected void onCreate(Bundle state)
	{
		super.onCreate(state);
		
		activity = this;
		mContext = this;
		mHandler = new Handler();
		mAssets = getAssets();
		
		if (mSoundPoolID > 1)
		{
			mSoundPoolID++;
		}
		else
		{
			mSoundPoolID = 1;
		}
		
		mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);
		//getResources().getAssets();
		
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
		
		metrics = new DisplayMetrics();
		getWindowManager().getDefaultDisplay().getMetrics(metrics);
		
		// Pre-load these, so the C++ knows where to find them
		
		::foreach ndlls::
		System.loadLibrary("::name::");::end::
		org.haxe.HXCPP.run("ApplicationMain");
		
		mView = new MainView(getApplication(), this);
		setContentView(mView);
		
		sensorManager = (SensorManager)activity.getSystemService(Context.SENSOR_SERVICE);
		
		if (sensorManager != null)
		{
			sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
			sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
		}
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
	
	
	public static void clearUserPreference(String inId)
	{
		SharedPreferences prefs = activity.getSharedPreferences(GLOBAL_PREF_FILE, MODE_PRIVATE);
		SharedPreferences.Editor prefEditor = prefs.edit();
		prefEditor.putString(inId, "");
		prefEditor.commit();
	}
	
	
	public void doPause()
	{
		if (mSoundPool != null)
		{
			mSoundPool.release();
		}
		mSoundPool = null;
		
		mView.sendActivity(NME.DEACTIVATE);
		mView.onPause();
		
		if (mMediaPlayer != null)
		{
			mMusicWasPlaying = mMediaPlayer.isPlaying();
			mMediaPlayer.pause();
		}
		
		if (sensorManager != null)
		{
			sensorManager.unregisterListener(this);
		}
	}
	
	
	public void doResume()
	{
		mSoundPoolID++;
		mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);
		
		mView.onResume();
		
		if (mMediaPlayer != null)
		{
			if (mMusicWasPlaying)
			{
				mMediaPlayer.start();
			}
		}
		
		mView.sendActivity(NME.ACTIVATE);
		
		if (sensorManager != null)
		{
			sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
			sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
		}
	}
	
	
	public static Context getContext()
	{
		return mContext;
	}
	
	
	public static GameActivity getInstance()
	{
		return activity;
	}
	
	
	public static boolean getMusicComplete()
	{
		return mMusicComplete;
	}
	
	
	public static int getMusicHandle(String inFilename)
    {
		int id = -1;
		
		Log.v("GameActivity", "Get music handle ------" + inFilename);
		
		::foreach assets::::if (type == "music")::if (inFilename.equals("::id::")) id = ::APP_PACKAGE::.R.raw.::flatName::;
		::end::::end::
		
		Log.v("GameActivity", "Got music handle ------" + id);
		
		return id;
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
			Log.e("GameActivity",  "getResource" + ":" + e.toString());
		}
		
		return null;
	}
	
	
	public static int getSoundHandle(String inFilename)
	{
		int id = -1;
		
		::foreach assets::::if (type == "sound")::if (inFilename.equals("::id::")) id = ::APP_PACKAGE::.R.raw.::flatName::;
		::end::::end::
		
		Log.v("GameActivity","Get sound handle ------" + inFilename + " = " + id);
		
		if (id > 0)
		{
			int index = mSoundPool.load(mContext, id, 1);
			Log.v("GameActivity", "Loaded index: " + index);
			return index;
		}
		else
		{
			Log.v("GameActivity", "Resource not found: " + (-id));
		}
		
		return -1;
    }
	
	
	public static int getSoundLength(int inResourceID)
	{
		MediaPlayer mp = MediaPlayer.create(mContext, inResourceID);
		
		if (mp == null)
		{
			return -1;
		}
		
		return mp.getDuration();
	}
	
	
	public static int getSoundPoolID()
	{
		return mSoundPoolID;
	}
	
	
	static public String getSpecialDir(int inWhich)
    {
		Log.v("GameActivity","Get special Dir " + inWhich);
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
		SharedPreferences prefs = activity.getSharedPreferences(GLOBAL_PREF_FILE, MODE_PRIVATE);
		return prefs.getString(inId, "");
	}
	
	
	public static void launchBrowser(String inURL)
	{
		Intent browserIntent = new Intent(Intent.ACTION_VIEW).setData(Uri.parse(inURL));
		
		try
		{
			activity.startActivity(browserIntent);
		}
		catch (Exception e)
		{
			Log.e("GameActivity", e.toString());
			return;
		}
	}
	
	
	private void loadNewSensorData(SensorEvent event)
	{
		final int type = event.sensor.getType();
		
		if (type == Sensor.TYPE_ACCELEROMETER)
		{
			accelData = event.values.clone();
			NME.onAccelerate(accelData[0], accelData[1], accelData[2]);
		}
		
		if (type == Sensor.TYPE_MAGNETIC_FIELD)
		{
			magnetData = event.values.clone();
			//Log.d("GameActivity","new mag: " + magnetData[0] + ", " + magnetData[1] + ", " + magnetData[2]);
		}
	}
	
	
	@Override public void onAccuracyChanged(Sensor sensor, int accuracy)
	{
		
	}
	
	
	@Override protected void onDestroy()
	{
		// TODO: Wait for result?
		mView.sendActivity(NME.DESTROY);
		activity = null;
		super.onDestroy();
	}
	
	
	@Override protected void onPause()
	{
		super.onPause();
		doPause();
	}
	
	
	@Override protected void onResume()
	{
		super.onResume();
		doResume();
	}
	
	@Override public void onSensorChanged(SensorEvent event)
	{
		loadNewSensorData(event);
		
		if (accelData != null && magnetData != null)
		{
			boolean foundRotationMatrix = SensorManager.getRotationMatrix(rotationMatrix, inclinationMatrix, accelData, magnetData);
			if (foundRotationMatrix)
			{
				SensorManager.getOrientation(rotationMatrix, orientData);
				NME.onOrientationUpdate(orientData[0], orientData[1], orientData[2]);
			}
		}
		
		NME.onDeviceOrientationUpdate(prepareDeviceOrientation());
		NME.onNormalOrientationFound(bufferedNormalOrientation);
	}
	
	
	public static void playMusic(String inFilename)
    {
		
    }
	
	
	public static int playMusic(int inResourceID, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
		if (mMediaPlayer != null)
		{
			Log.v("GameActivity", "stop MediaPlayer");
			mMediaPlayer.stop();
			mMediaPlayer = null;
		}
		
		mMusicComplete = false;
		mMediaPlayer = MediaPlayer.create(mContext, inResourceID);
		
		if (mMediaPlayer == null)
		{
			return -1;
		}
		
		mMediaPlayer.setVolume((float)inVolLeft, (float)inVolRight);
		
		if (inLoop < 0)
		{
			mMediaPlayer.setLooping(true);
		}
		else if (inLoop >= 0)
		{
			mMusicLoopsLeft = inLoop;
			mMediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener()
			{
				@Override public void onCompletion(MediaPlayer mp)
				{
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
	
	
	public static int playSound(int inSoundID, double inVolLeft, double inVolRight, int inLoop)
	{
		Log.v("GameActivity", "PlaySound -----" + inSoundID);
		return mSoundPool.play(inSoundID, (float)inVolLeft, (float)inVolRight, 1, inLoop, 1.0f);
	}
	
	
	public static void popView()
	{
		activity.setContentView(activity.mView);
		activity.doResume();
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
		int rawOrientation = getWindow().getWindowManager().getDefaultDisplay().getOrientation();
		
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
	
	
	public static void pushView(View inView)
	{
		activity.doPause();
		activity.setContentView(inView);
	}
	
	
	public static void setMusicTransform(double inVolLeft, double inVolRight)
	{
		if (mMediaPlayer==null)
		{
			return;
		}
		
		mMediaPlayer.setVolume((float)inVolLeft, (float)inVolRight);
	}
	
	
	public static void setUserPreference(String inId, String inPreference)
	{
		SharedPreferences prefs = activity.getSharedPreferences(GLOBAL_PREF_FILE, MODE_PRIVATE);
		SharedPreferences.Editor prefEditor = prefs.edit();
		prefEditor.putString(inId, inPreference);
		prefEditor.commit();
	}
	
	
	public static void showKeyboard(boolean show)
	{
		InputMethodManager mgr = (InputMethodManager)activity.getSystemService(Context.INPUT_METHOD_SERVICE);
		mgr.hideSoftInputFromWindow(activity.mView.getWindowToken(), 0);
		
		if (show)
		{
			mgr.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
			// On the Nexus One, SHOW_FORCED makes it impossible
			// to manually dismiss the keyboard.
			// On the Droid SHOW_IMPLICIT doesn't bring up the keyboard.
		}
	}
	
	
	public static void stopMusic()
	{
		Log.v("GameActivity", "stop MediaPlayer");
		
		if (mMediaPlayer != null)
		{
			mMediaPlayer.stop();
		}
	}
	
	
	static public void stopSound(int inStreamID)
	{
		if (mSoundPool != null)
		{
			mSoundPool.stop (inStreamID);
		}
	}
	
	
	public static void vibrate(int period, int duration)
	{
		Vibrator v = (Vibrator)activity.getSystemService(Context.VIBRATOR_SERVICE);
		
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
