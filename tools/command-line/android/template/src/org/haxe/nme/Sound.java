package org.haxe.nme;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileDescriptor;
import java.io.FileNotFoundException;
import java.io.IOException; 
import java.util.HashSet;

import android.content.Context;
import android.util.Log;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.Uri;

public class Sound
{
	private static Context mContext;
	private static Sound instance;

	private static HashSet<MediaPlayer> mpSet = new HashSet<MediaPlayer>();
	private static boolean mMusicComplete = true;
	private static int mMusicLoopsLeft = 0;
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

        for (MediaPlayer mp : mpSet) {
            if (mp != null && mp.isPlaying()) {
				mMusicWasPlaying = mp.isPlaying();
				mp.pause();
            }
        }
	}

	public void doResume()
	{
		mSoundPoolID++;
		mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);

        for (MediaPlayer mp : mpSet) {
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
		
		if (id > 0)
		{
			int index = mSoundPool.load(mContext, id, 1);
			Log.v("Sound", "Loaded index: " + index);
			return index;
		}
		else
		{
			Log.v("Sound", "Resource not found: " + (-id));
			int index = mSoundPool.load(inFilename, 1);
			Log.v("Sound", "Loaded index from path: " + index);
			return index;
		}
		
		//return -1;
    }
	
	public static int getSoundLength(String inFilename)
	{
		int id = GameActivity.getResourceID(inFilename);

		if (id > 0) {
			MediaPlayer mp = MediaPlayer.create(mContext, id);
			
			if (mp != null) {
				int duration = mp.getDuration();
				mp.release();
				return duration;
			}
		}
		return -1;
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
	
	public static int getMusicHandle(String inFilename)
    {
		int id = GameActivity.getResourceID(inFilename);
		
		Log.v("Sound","Get music handle ------" + inFilename + " = " + id);
		
		/*if (id > 0)
		{
			int index = mSoundPool.load(mContext, id, 1);
			Log.v("Sound", "Loaded index: " + index);
			return index;
		}
		else
		{
			Log.v("Sound", "Resource not found: " + (-id));
			int index = mSoundPool.load(inFilename, 1);
			Log.v("Sound", "Loaded index from path: " + index);
			return index;
		}*/
		
		return id;		
	}

	public static int playMusic(int inResourceID, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
    	Log.i("Sound", "playMusic");
		/*if (mMediaPlayer != null) {
			Log.v("Sound", "stop MediaPlayer");
			mMediaPlayer.stop();
			mMediaPlayer = null;
		}*/
		
		mMusicComplete = false;
		MediaPlayer mp = MediaPlayer.create(mContext, inResourceID);
		
		if (mp == null) {
			return -1;
		}
		return playMediaPlayer(mp, inVolLeft, inVolRight, inLoop, inStartTime);
	}

	public static int playMusic(String inFilename, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
    	Log.i("Sound", "playMusic");
		/*if (mMediaPlayer != null) {
			Log.v("Sound", "stop MediaPlayer");
			mMediaPlayer.stop();
			mMediaPlayer = null;
		}*/
		
		mMusicComplete = false;

		MediaPlayer mp = null;

		if (inFilename.charAt(0) == File.separatorChar) {
			try {
	        	FileInputStream fis = new FileInputStream(new File(inFilename));
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
			Uri uri = Uri.parse(inFilename);
			mp = MediaPlayer.create(mContext, uri);
	    }

		if (mp == null) {
			return -1;
		}

		return playMediaPlayer(mp, inVolLeft, inVolRight, inLoop, inStartTime);
	}
		
	private static int playMediaPlayer(MediaPlayer mp, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
	{
		if (inLoop < 0) {
			mp.setLooping(true);
		} else if (inLoop >= 0) {
			mMusicLoopsLeft = inLoop;
			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener()
			{
				@Override public void onCompletion(MediaPlayer mp)
				{
					if (--mMusicLoopsLeft > 0) {
						mp.seekTo(0);
						mp.start();
					} else {
						mMusicComplete = true;
						mp.stop();
						mp.release();
					}
				}
			});
		}
		
        mpSet.add(mp);
		setMusicVolume(mp, inVolLeft, inVolRight);
		mp.seekTo((int)inStartTime);
		mp.start();
		
		return 0;
	}

	public static void stopMusic()
	{
		Log.v("Sound", "stopMusic");
        for (MediaPlayer mp : mpSet) {
            if (mp != null) {
				mp.stop();
            }
        }
	}
	
	public static boolean getMusicComplete()
	{
		return mMusicComplete;
	}

	public static void setMusicTransform(double inVolLeft, double inVolRight)
	{
        for (MediaPlayer mp : mpSet) {
            if (mp != null) {
            	setMusicVolume(mp, inVolLeft, inVolRight);
            }
        }
	}

	private static void setMusicVolume(MediaPlayer mp, double inVolLeft, double inVolRight)
	{
		mp.setVolume((float)inVolLeft, (float)inVolRight);
	}
}
	