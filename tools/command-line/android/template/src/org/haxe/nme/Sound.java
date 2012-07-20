package org.haxe.nme;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileDescriptor;
import java.io.FileNotFoundException;
import java.io.IOException; 
import java.util.Hashtable;

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

	public ManagedMediaPlayer(MediaPlayer mp, float leftVol, float rightVol, int loop) {
		this.mp = mp;
		setVolume(leftVol, rightVol);
		isComplete = false;
		final ManagedMediaPlayer mmp = this;

		if (loop < 0) {
			mp.setLooping(true);
		} else if (loop >= 0) {
			this.loopsLeft = loop;
			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override public void onCompletion(MediaPlayer mp) {
					if (--mmp.loopsLeft > 0) {
						mp.seekTo(0);
						mp.start();
					} else {
						mmp.setComplete();
					}
				}
			});
		}
	}

	public ManagedMediaPlayer setMediaPlayer(MediaPlayer mp) {
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

	public int getCurrentPosition() {
		if (mp != null)
			return mp.getCurrentPosition();
		return -1;
	}

	public void stop() {
		if (mp != null)
			mp.stop();
		release();
	}

	public void setComplete() {
		this.isComplete = true;
		stop();
	}

	public void release() {
		if (mp != null)
			mp.release();
	}
}

public class Sound
{
	private static Context mContext;
	private static Sound instance;

	private static Hashtable<String, ManagedMediaPlayer> mediaPlayers = new Hashtable<String, ManagedMediaPlayer>();
	private static boolean mMusicWasPlaying = false;
	private static SoundPool mSoundPool;
	private static int mSoundPoolID = 0;

    public Sound(Context context)
    {
    	if (instance == null) {
			mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);

			if (mSoundPoolID > 1) {
				mSoundPoolID++;
			} else {
				mSoundPoolID = 1;
			}
		}

    	instance = this;
    	mContext = context;
    }
	
	public void doPause()
	{
		if (mSoundPool != null) {
			mSoundPool.release();
		}
		mSoundPool = null;

		MediaPlayer mp;
		for (ManagedMediaPlayer mmp : mediaPlayers.values()) {
			mp = mmp.mp;
            if (mp.isPlaying()) {
				mMusicWasPlaying = mp.isPlaying();
				mp.pause();
            }
        }
	}

	public void doResume()
	{
		mSoundPoolID++;
		mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);

		MediaPlayer mp;
		for (ManagedMediaPlayer mmp : mediaPlayers.values()) {
			mp = mmp.mp;
            if (mp != null && mMusicWasPlaying) {
				mp.start();
            }
        }
	}
	
	/*
	 * Sound effects using SoundPool
	 *
	 * This allows for low latency and CPU load but sounds must be 100kB or smaller
	 */

	public static int getSoundHandle(String inFilename)
	{
		int id = GameActivity.getResourceID(inFilename);
		
		Log.v("Sound","Get sound handle ------" + inFilename + " = " + id);
		
		if (id > 0) {
			int index = mSoundPool.load(mContext, id, 1);
			Log.v("Sound", "Loaded index: " + index);
			return index;
		} else {
			Log.v("Sound", "Resource not found: " + (-id));
			int index = mSoundPool.load(inFilename, 1);
			Log.v("Sound", "Loaded index from path: " + index);
			return index;
		}
		
		//return -1;
    }
	
	public static int getSoundPoolID()
	{
		return mSoundPoolID;
	}

	public static int playSound(int inResourceID, double inVolLeft, double inVolRight, int inLoop)
	{
		Log.v("Sound", "PlaySound -----" + inResourceID);
		
		if (inLoop > 0) {
			inLoop--;
		}
		
		return mSoundPool.play(inResourceID, (float)inVolLeft, (float)inVolRight, 1, inLoop, 1.0f);
	}
	
	static public void stopSound(int inStreamID)
	{
		if (mSoundPool != null) {
			mSoundPool.stop(inStreamID);
		}
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

	public static int playMusic(String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
    	Log.i("Sound", "playMusic");

		MediaPlayer mp = null;
		int resourceID = getMusicHandle(inPath); // check to see if this is a bundled resource
		if (resourceID < 0) { // not in bundle, try to play from filesystem
			if (inPath.charAt(0) == File.separatorChar) {
				try {
		        	FileInputStream fis = new FileInputStream(new File(inPath));
			        FileDescriptor fd = fis.getFD();
					mp = new MediaPlayer();
					mp.setDataSource(fd);
					mp.prepare();
		        } catch(FileNotFoundException e) { 
		            System.out.println(e.getMessage());
		            return -1;
		        } catch(IOException e) { 
		            System.out.println(e.getMessage());
		            return -1;
		        }
		    } else {
				Uri uri = Uri.parse(inPath);
				mp = MediaPlayer.create(mContext, uri);
		    }
		} else {
			mp = MediaPlayer.create(mContext, resourceID);
		}

		if (mp == null) {
			return -1;
		}

		return playMediaPlayer(mp, inPath, inVolLeft, inVolRight, inLoop, inStartTime);
	}
		
	private static int playMediaPlayer(MediaPlayer mp, final String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
	{	
		ManagedMediaPlayer mmp;
		if (mediaPlayers.containsKey(inPath))
			mmp = mediaPlayers.get(inPath).setMediaPlayer(mp);
		else
			mmp = new ManagedMediaPlayer(mp, (float)inVolLeft, (float)inVolRight, inLoop);

        mediaPlayers.put(inPath, mmp);
		mp.seekTo((int)inStartTime);
		mp.start();

		return 0;
	}

	public static void stopMusic(String inPath)
	{
		Log.v("Sound", "stopMusic");
		
		if (mediaPlayers.containsKey(inPath))
			mediaPlayers.get(inPath).stop();
	}
	
	public static int getDuration(String inPath)
	{
		if (mediaPlayers.containsKey(inPath))
			return mediaPlayers.get(inPath).getDuration();
		return -1;
	}
	
	public static int getPosition(String inPath)
	{
		if (mediaPlayers.containsKey(inPath))
			return mediaPlayers.get(inPath).getCurrentPosition();
		return -1;
	}
	
	public static double getLeft(String inPath)
	{
		if (mediaPlayers.containsKey(inPath))
			return mediaPlayers.get(inPath).leftVol;
		return -1;
	}
	
	public static double getRight(String inPath)
	{
		if (mediaPlayers.containsKey(inPath))
			return mediaPlayers.get(inPath).rightVol;
		return -1;
	}
	
	public static boolean getComplete(String inPath)
	{
		if (mediaPlayers.containsKey(inPath))
			return mediaPlayers.get(inPath).isComplete;
		return true;
	}

	public static void setMusicTransform(String inPath, double inVolLeft, double inVolRight)
	{
		if (mediaPlayers.containsKey(inPath))
			mediaPlayers.get(inPath).setVolume((float)inVolLeft, (float)inVolRight);
	}
}
	