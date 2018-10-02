package org.haxe.nme;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileDescriptor;
import java.io.FileNotFoundException;
import java.io.IOException; 
import java.lang.System;
import java.security.MessageDigest;
// import java.util.Hashtable;
import java.util.HashMap;
import java.util.Map;
import java.util.zip.CRC32;

import android.content.Context;
import android.util.Log;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.Uri;

class ManagedMediaPlayer
{
	public MediaPlayer mp;
	public float leftVol;
	public float rightVol;
	public boolean isComplete = true;
	public int loopsLeft = 0;
	public boolean wasPlaying = false;
	public String pathId;
   final public String tag="Sound MMMP";

	public ManagedMediaPlayer(MediaPlayer mp, float leftVol, float rightVol, int inLoops ,String inPathId) {
		this.mp = mp;
		setVolume(leftVol, rightVol);
		isComplete = false;
      pathId = inPathId;
		final ManagedMediaPlayer mmp = this;
      Log.v(tag, "ManagedMediaPlayer - " + inPathId + " loops " + inLoops );

		if (inLoops  < 0 )
      {
         Log.v(tag, "ManagedMediaPlayer - set looping true " );
			mp.setLooping(true);
		}
      else if (inLoops  >= 0)
      {
			loopsLeft = inLoops ;

			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override public void onCompletion(MediaPlayer mp) {
               Log.v(tag, "ManagedMediaPlayer - onCompletion " + mmp.loopsLeft );
					if (--mmp.loopsLeft > 0) {
                  double t0  = System.currentTimeMillis();
                  Log.v(tag, "ManagedMediaPlayer - seek 0");
						mp.seekTo(0);
						mp.start();
                  Log.v(tag, "ManagedMediaPlayer - start " + (System.currentTimeMillis()-t0) + "ms" );
					} else {
						mmp.setComplete();
					}
				}
			});
		}
	}

	public ManagedMediaPlayer setMediaPlayer(MediaPlayer mp) {
      Log.v(tag, "ManagedMediaPlayer - setMediaPlayer" );
		this.mp = mp;
		return this;
	}

	public void setVolume(float leftVol, float rightVol) {
		if (mp != null)
			mp.setVolume((float)leftVol, (float)rightVol);
		this.leftVol = leftVol;
		this.rightVol = rightVol;
	}

	public int getDuration() {
		if (mp != null)
			return mp.getDuration();
		return -1;
	}

	public void setCurrentPosition(int position) {
      Log.v(tag, "ManagedMediaPlayer - setCurrentPosition " + position );
		if (mp != null)
			mp.seekTo(position);
	}
	public int getCurrentPosition() {
		if (mp != null)
			return mp.getCurrentPosition();
		return -1;
	}
	
	public boolean isPlaying() {
		return mp!=null && mp.isPlaying();
	}
	
	public void pause() {
		if (mp != null)
			mp.pause();
	}
	
	public void start() {
		if (mp != null)
			mp.start();
	}

	public void stop() {
		if (mp != null)
      {
         //Log.e("ManagedMediaPlayer", "mp.stop");
         MediaPlayer mpTemp = mp;
         mp = null;
			mpTemp.release();
      }
      //Log.e("ManagedMediaPlayer", "mp.stopped");
	}

	public void setComplete() {
		this.isComplete = true;
		stop();
	}

	public void release() {
      Log.e(tag, "release " + mp);
		if (mp != null) {
         MediaPlayer mpTemp = mp;
			mp = null;
			mpTemp.release();
		}
	}
}

public class Sound implements SoundPool.OnLoadCompleteListener
{
	private static Context mContext;
	private static Sound instance;

	private static ManagedMediaPlayer mediaPlayer;
	private static boolean mediaPlayerWasPlaying;
	private static SoundPool mSoundPool;
	// private static int mSoundPoolID = 0;
	private static long mTimeStamp = 0;

   // Already loaded soundIds...
	private static HashMap<Integer, Integer> mResourceToSoundId;
	private static HashMap<String, Integer> mFilenameToSoundId;
   // Duration for given soundId
	private static HashMap<Integer, Long> mSoundDuration;
	private static HashMap<Integer, Boolean> mSoundIdLoaded;

   // Playing StreamId static
	private static HashMap<Integer, Long> mSoundProgress;

    public Sound(Context context)
    {
    	if (instance == null) {
    		mResourceToSoundId = new HashMap<Integer, Integer>();
    		mFilenameToSoundId = new HashMap<String, Integer>();

    		mSoundIdLoaded = new HashMap<Integer, Boolean>();

    		mSoundProgress = new HashMap<Integer, Long>();
    		mSoundDuration = new HashMap<Integer, Long>();

    		mTimeStamp = System.currentTimeMillis();
			mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);
         mSoundPool.setOnLoadCompleteListener(this);
		}

    	instance = this;
    	mContext = context;
    }

   public void onLoadComplete(SoundPool soundPool,int sampleId,int status)
   {
      Log.v("Sound","onLoadComplete " + sampleId + "=" + status);
      mSoundIdLoaded.put(sampleId,true);
   }
	
	public void doPause()
	{
		if (mSoundPool != null) {
			mSoundPool.autoPause();
		}
		
		if (mediaPlayer != null) {
			mediaPlayerWasPlaying = mediaPlayer.isPlaying ();
			mediaPlayer.pause();
		}
	}

	public void doResume()
	{
		mTimeStamp = System.currentTimeMillis();
		mSoundPool.autoResume();

		if (mediaPlayer != null && mediaPlayerWasPlaying) {
			mediaPlayer.start ();
		}	
	}
	
	/*
	 * Sound effects using SoundPool
	 *
	 * This allows for low latency and CPU load but sounds must be 100kB or smaller
    *
    *  Resturns a soundId
	 */

	public static int getSoundHandle(String inFilename)
	{
		int resourceId = GameActivity.getResourceID(inFilename);
		Log.v("Sound","Get sound handle " + inFilename + " = " + resourceId);

		if (resourceId > 0)
      {
         if ( mResourceToSoundId.get(resourceId)!=null)
         {
			   int soundId = mResourceToSoundId.get(resourceId);
			   //Log.v("Sound", "Already loaded " + soundId );
            return soundId;
         }

			int soundId = mSoundPool.load(mContext, resourceId, 1);
         mResourceToSoundId.put(resourceId, soundId);
         mSoundIdLoaded.put(soundId,false);
		   int duration = getDuration(resourceId);
			Log.v("Sound", "Loaded resource " + resourceId + " to " + soundId + " duration = " + mSoundDuration);
		   mSoundDuration.put(soundId, (long)duration);
         return soundId;
		}
      else
      {
         if (mFilenameToSoundId.get(inFilename)!=null)
         {
			   int soundId = mFilenameToSoundId.get(inFilename);
			   //Log.v("Sound", "Already loaded file " + soundId );
            return soundId;
         }

			Log.v("Sound", "Resource not found, assume filesystem: " + inFilename);
			int soundId = mSoundPool.load(inFilename, 1);
         mFilenameToSoundId.put(inFilename, soundId);
         // Not complete yet
         mSoundIdLoaded.put(soundId,false);

		   int duration = getDuration(inFilename);
		   mSoundDuration.put(soundId, (long)duration);
			Log.v("Sound", "Loaded sound from " + inFilename + " to " + soundId + " duration =" + duration);

         return soundId;
		}
    }
	
	public static String getSoundPathByByteArray(byte[] data) throws java.lang.Exception
	{
		// HACK! It seems that the API doesn't allow to use non file streams. At least with MediaPlayer/SoundPool. 
		// The alternative is to use an AudioTrack, but the data should be decoded by hand and not sure if android
		// provides an API for decoding this kind of stuff.
		// So the partial solution at this point is to create a temporary file that will be loaded.
		
		MessageDigest messageDigest = MessageDigest.getInstance("md5");
		messageDigest.update(data);
		String md5 = new java.math.BigInteger(1, messageDigest.digest()).toString(16);
		File file = new File(mContext.getCacheDir() + "/" + md5 + ".wav");

		//File file = File.createTempFile("temp", ".sound", mContext.getFilesDir());
		if (!file.exists()) {
			Log.v("Sound", "Created temp sound file :" + file.getAbsolutePath());
			java.io.FileOutputStream fileOutputStream = new java.io.FileOutputStream(file);
			fileOutputStream.write(data);
			fileOutputStream.flush();
			fileOutputStream.close();
		} else {
			Log.v("Sound", "Opened temp sound file :" + file.getAbsolutePath());
		}
		
		return file.getAbsolutePath();
	}
	
	public static int playSound(int inSoundId, double inVolLeft, double inVolRight, int inLoop)
	{
		Log.v("Sound", "PlaySound " + inSoundId);
		
		inLoop--;
		if (inLoop < 0) {
			inLoop = 0;
		}

      int tries = 0;
      while( !mSoundIdLoaded.get(inSoundId) )
      {
		   Log.v("Sound", "wait loaded...");
         try { java.lang.Thread.sleep(5); } catch (InterruptedException e) { break; }
         tries++;
         if (tries>50)
            break;
      }
		
		int streamId = mSoundPool.play(inSoundId, (float)inVolLeft, (float)inVolRight, 1, inLoop, 1.0f);
		mSoundProgress.put(streamId, (long)0);
		return streamId;
	}
	
	static public void stopSound(int inStreamID)
	{
		if (mSoundPool != null) {
			mSoundPool.stop(inStreamID);
			mSoundProgress.remove(inStreamID);
		}
	}

	static public void checkSoundCompletion() 
	{
		long delta = (System.currentTimeMillis() - mTimeStamp);
		for (Map.Entry<Integer, Long> entry : mSoundProgress.entrySet()) {
			long val = entry.getValue();
			entry.setValue(val + (long)delta);
		}

		mTimeStamp = System.currentTimeMillis();
	}

	static public boolean getSoundComplete(int inSoundID, int inStreamID, int inLoop) {
		if (!mSoundProgress.containsKey(inStreamID) || !mSoundDuration.containsKey(inSoundID)) {
			return true;
		}

		return mSoundProgress.get(inStreamID) >= (mSoundDuration.get(inSoundID) * inLoop);
	}

	static public int getSoundPosition(int inSoundID, int inStreamID, int inLoop) {
		if (!mSoundProgress.containsKey(inStreamID) || !mSoundDuration.containsKey(inSoundID)) {
			return 0;
		}

		long progress = mSoundProgress.get(inStreamID);
		long total = mSoundDuration.get(inSoundID);
		return (int)(progress > (total * inLoop) ? total : (progress % total));
	}

	/*
	 * Music using MediaPlayer
	 *
	 * This allows for larger audio files but consumes more CPU than SoundPool
	 */
	
	private static int getMusicHandle(String inPath)
    {
		int id = GameActivity.getResourceID(inPath);
		Log.v("Sound","Get music handle ------" + inPath + " = " + id);	
		return id;		
	}

	private static MediaPlayer createMediaPlayer(String inPath) 
	{
      double t0 = System.currentTimeMillis();
		MediaPlayer mp = null;
		int resId = getMusicHandle(inPath);
      Log.v("Sound", "getMusicHandle " + inPath + " =" + resId);
		if (resId < 0) {
			if (inPath.charAt(0) == File.separatorChar) {
           Log.v("Sound", "looks like filename");
				try {
		        	FileInputStream fis = new FileInputStream(new File(inPath));
			        FileDescriptor fd = fis.getFD();
					mp = new MediaPlayer();
					mp.setDataSource(fd);
					mp.prepare();
		        } catch(FileNotFoundException e) { 
		            System.out.println(e.getMessage());
		            return null;
		        } catch(IOException e) { 
		            System.out.println(e.getMessage());
		            return null;
		        }
		    } else {
				Uri uri = Uri.parse(inPath);
           Log.v("Sound", "looks like uri " + uri);
				mp = MediaPlayer.create(mContext, uri);
		    }
		} else {
         Log.v("Sound", "looks like resource " + resId);
			mp = MediaPlayer.create(mContext, resId);
		}

		Log.v("Sound", "Created media player " + mp + " : " + (System.currentTimeMillis()-t0) + "ms" );
		return mp;
	}

	public static int playMusic(String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
    	Log.i("Sound", "playMusic " + inPath + " x" + inLoop);
		
		if (mediaPlayer != null) {
			mediaPlayer.stop();
         mediaPlayer = null;
		}
		
		MediaPlayer mp = createMediaPlayer(inPath);
		if (mp == null) {
			return -1;
		}

		return playMediaPlayer(mp, inPath, inVolLeft, inVolRight, inLoop, inStartTime);
	}
		
	private static int playMediaPlayer(MediaPlayer mp, final String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
	{	
		mediaPlayer = new ManagedMediaPlayer(mp, (float)inVolLeft, (float)inVolRight, inLoop, inPath);
		mp.seekTo((int)inStartTime);
		mediaPlayer.start();

		return 0;
	}

	public static void stopMusic(String inPath)
	{
		Log.v("Sound", "stopMusic");
		
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			mediaPlayer.stop();
		}
	}
	
	public static int getDuration(String inPath)
	{
		int duration = -1;
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			duration = mediaPlayer.getDuration ();
		} else {
			MediaPlayer mp = createMediaPlayer(inPath);
			if (mp != null) {
				duration = mp.getDuration();
				mp.release();
			}
		}

		return duration;
	}

	
	public static int getDuration(int inResourceId)
	{
		int duration = -1;
		MediaPlayer mp = MediaPlayer.create(mContext, inResourceId);
		if (mp != null)
      {
			duration = mp.getDuration();
			mp.release();
		}
		return duration;
	}


	public static void setPosition(int position) {
		mediaPlayer.setCurrentPosition(position);
	}
	
	public static int getPosition(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			return mediaPlayer.getCurrentPosition ();
		}
		return -1;
	}
	
	public static double getLeft(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			return mediaPlayer.leftVol;
		}

		return 0.5;
	}
	
	public static double getRight(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			return mediaPlayer.rightVol;
		}

		return 0.5;
	}
	
	public static boolean getComplete(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			return mediaPlayer.isComplete;
		}

		return true;
	}

	public static void setMusicTransform(String inPath, double inVolLeft, double inVolRight)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayer.pathId)) {
			mediaPlayer.setVolume((float)inVolLeft, (float)inVolRight);
		}
	}
}
	
