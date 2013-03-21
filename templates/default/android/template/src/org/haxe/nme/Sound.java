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

import android.content.res.Resources;
import android.content.ContentResolver;

import java.util.ArrayList;

public class Sound implements SoundPool.OnLoadCompleteListener
{
	private static Context mContext;
	private static Sound instance;

	private static Hashtable<Integer, Integer> soundPoolIndices = new Hashtable<Integer, Integer>();

	private static MediaPlayer mediaPlayer;
	private static boolean mMusicWasPlaying = false;
	private static SoundPool mSoundPool;
	private static int mSoundPoolID = 0;

	private static int mSoundPoolIndex = 0;
	private static int soundpoolPolyphony = 8;
	
	private static int loadsRequested = 0;
	private static int loadsCompleted = 0;
	
	private static AudioManager mAudioManager;
    public Sound(Context context)
    {
    	if (instance == null) {
			mSoundPool = new SoundPool(soundpoolPolyphony, AudioManager.STREAM_MUSIC, 0);
			mSoundPool.setOnLoadCompleteListener(this);
			if (mSoundPoolID > 1) {
				mSoundPoolID++;
			} else {
				mSoundPoolID = 1;
			}
		}

    	instance = this;
    	mContext = context;
    	mAudioManager = (AudioManager)mContext.getSystemService(Context.AUDIO_SERVICE);
    }
	
    public void onLoadComplete(SoundPool soundPool, int sampleId, int status){
    	//Log.v("Sound", "Soundpool load complete for id "+sampleId);
		loadsCompleted++;
    	_poolReady = loadsRequested==loadsCompleted?1:0;
    	//Log.v("Sound", loadsRequested+"/"+loadsCompleted);
    }
    
	public void doPause()
	{
		mSoundPool.autoPause();
		
		if (mediaPlayer != null) {
			mMusicWasPlaying = mediaPlayer.isPlaying ();
			mediaPlayer.pause();
		}
		
	}

	public void doResume()
	{
		mSoundPool.autoResume();

		if (mediaPlayer != null && mMusicWasPlaying && !mAudioManager.isMusicActive()) {
			mediaPlayer.start ();
		}	
		
	}
	private static int _poolReady = 0;
	public static int isPoolReady(){
		return _poolReady;
	}
	/*
	 * Sound effects using SoundPool
	 *
	 * This allows for low latency and CPU load but sounds must be 100kB or smaller
	 */

	public static int getSoundHandle(String inFilename)
	{
		int id = GameActivity.getResourceID(inFilename);
		if(soundPoolIndices.containsKey(id)){
			int index = soundPoolIndices.get(id);
			//Log.v("Sound", "Returning existing index: "+index);
			return index;
		}
		
		//Log.v("Sound","Get sound handle ------" + inFilename + " = " + id);
		
		if (id > 0) {
			int index = mSoundPool.load(mContext, id, 1);
			//Log.v("Sound", "Loaded index: " + index);
			soundPoolIndices.put(id, index);
			loadsRequested++;
			return index;
		} else {
			int index = mSoundPool.load(inFilename, 1);
			loadsRequested++;
			return index;
		}
		
		//return -1;
    }
	
	public static int getSoundPoolID()
	{
		return mSoundPoolID;
	}

	public static int playSound(int inResourceID, double inVolLeft, double inVolRight, int inLoop, int priority, double rate)
	{
		//Log.v("Sound", "PlaySound -----" + inResourceID);
		
		if (inLoop > 0) {
			inLoop--;
		}
		
		return mSoundPool.play(inResourceID, (float)inVolLeft, (float)inVolRight, priority, inLoop, (float)rate);
	}
	
	static public SoundPool getPool(){
		return mSoundPool;
	}
	
	static public void stopSound(int inStreamID)
	{
		//Log.v("Sound","Stop sound: "+inStreamID);
		if (mSoundPool != null) {
			mSoundPool.stop(inStreamID);
		}
	}
	static public void pauseSound(int id){
		if(mSoundPool != null){
			mSoundPool.pause(id);
		}
	}
	static public void resumeSound(int id){
		if(mSoundPool != null){
			mSoundPool.resume(id);
		}
	}
	static public void autoPause(){
		if(mSoundPool != null){
			mSoundPool.autoPause();
		}
	}
	static public void autoResume(){
		if(mSoundPool != null){
			mSoundPool.autoResume();
		}
	}
	static public void unloadSound(int inStreamID){
		if(mSoundPool!=null){
			mSoundPool.unload(inStreamID);
		}
	}
	static public void releasePool(){
		if(mSoundPool!=null){
			mSoundPool.release();
		}
	}
	static public void setVolume(int id, double left, double right){
		if(mSoundPool!=null){
			mSoundPool.setVolume(id,(float) left,(float) right);
		}
	}
	static public void setLoop(int id, int loop){
		if(mSoundPool!=null){
			mSoundPool.setLoop(id,loop);
		}
	}
	static public void setRate(int id, double rate){
		if(mSoundPool!=null){
			mSoundPool.setRate(id,(float)rate);
		}
	}
	
	static void clearPool(){
		//Log.v("Sound", "Clear pool");
		soundPoolIndices.clear();
		mSoundPool.release();
		mSoundPoolID++;
		mSoundPool = new SoundPool(soundpoolPolyphony, AudioManager.STREAM_MUSIC, 0);
	}


	/*
	 * Music using MediaPlayer
	 *
	 * This allows for larger audio files but consumes more CPU than SoundPool
	 */
	
	private static int getMusicHandle(String inPath)
    {
		int id = GameActivity.getResourceID(inPath);
		//Log.v("Sound","Get music handle ------" + inPath + " = " + id);	
		return id;		
	}

	private static boolean musicIsPlaying = false;
	private static boolean mediaPlayerReleased = true;
	public static int playMusic(String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
		/* this seems.. unstable
		if(mAudioManager.isMusicActive()){
			Log.v("Sound","Music was already active, not playing");
			return -1;
		}
		*/
		if(musicIsPlaying){
			stopMusic(inPath);
		}
    	//Log.i("Sound", "playMusic "+inPath);

    	if(mediaPlayer==null||mediaPlayerReleased){
        	Log.i("Sound", "Creating a new mediaplayer");
    		mediaPlayerReleased = false;
    		mediaPlayer = new MediaPlayer();
    		mediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener(){
    			public void onPrepared(MediaPlayer mp){
    				mp.start();
    			}
    		});
    	}
    	musicIsPlaying = true;

		return playMediaPlayer(mediaPlayer, inPath, inVolLeft, inVolRight, inLoop, inStartTime);
	}
	private static Uri foo(Context context, int id){
		Resources resources = context.getResources();
		return Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + resources.getResourcePackageName(id) + '/' + resources.getResourceTypeName(id) + '/' + resources.getResourceEntryName(id) );
	}
	private static int playMediaPlayer(MediaPlayer mp, final String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
	{	
		int resourceID = getMusicHandle(inPath); // check to see if this is a bundled resource

    	//Log.i("Sound", "Checking for resource id: "+resourceID);
		try{
			if (resourceID < 0) { // not in bundle, try to play from filesystem

		    	//Log.i("Sound", "Not bundled, checking filesystem");
				if (inPath.charAt(0) == File.separatorChar) {
					try {
			        	FileInputStream fis = new FileInputStream(new File(inPath));
				        FileDescriptor fd = fis.getFD();
						mp.setDataSource(fd);
				    	//Log.i("Sound", "Data source set from file descriptor");
							
			        } catch(FileNotFoundException e) { 
			            System.out.println(e.getMessage());
			            return -1;
			        } catch(IOException e) { 
			            System.out.println(e.getMessage());
			            return -1;
			        }
			    } else {
					/*Uri uri = Uri.parse(inPath);
					mp = MediaPlayer.create(mContext, uri);*/
			    }
			}else{
				//Log.i("Sound","Setting from resource id");
				mp.setDataSource(mContext, foo(mContext,resourceID));
			}
			mp.setLooping(inLoop>0 || inLoop == -1);
			if(inStartTime!=0) mp.seekTo((int)inStartTime);
			mp.prepare();
		}catch(Exception e){
			e.printStackTrace();
			return -1;
		}
		
		//ManagedMediaPlayer mmp;
		//if (mediaPlayers.containsKey(inPath))
			//mmp = mediaPlayers.get(inPath).setMediaPlayer(mp);
		//else
			//mmp = new ManagedMediaPlayer(mp, (float)inVolLeft, (float)inVolRight, inLoop);

        //mediaPlayers.put(inPath, mmp);

		return 0;
	}

	public static void stopMusic(String inPath)
	{

		Log.v("Sound", "stopMusic");
		if (mediaPlayer != null) {
			mediaPlayer.stop ();
			mediaPlayer.reset();
		}
    	musicIsPlaying = false;
	}
	
	public static int getDuration(String inPath)
	{
		if (mediaPlayer != null) {
			return mediaPlayer.getDuration ();
		}
		
		//if (mediaPlayers.containsKey(inPath))
		//	return mediaPlayers.get(inPath).getDuration();
		return -1;
	}
	
	public static int getPosition(String inPath)
	{
		if (mediaPlayer != null) {
			return mediaPlayer.getCurrentPosition ();
		}
		
		//if (mediaPlayers.containsKey(inPath))
		//	return mediaPlayers.get(inPath).getCurrentPosition();
		return -1;
	}
	
	public static double getLeft(String inPath)
	{
		return 0.5;
		
		//if (mediaPlayers.containsKey(inPath))
		//	return mediaPlayers.get(inPath).leftVol;
		//return -1;
	}
	
	public static double getRight(String inPath)
	{
		return 0.5;
		
		//if (mediaPlayers.containsKey(inPath))
		//	return mediaPlayers.get(inPath).rightVol;
		//return -1;
	}
	
	public static boolean getComplete(String inPath)
	{
		return true;
		
		//if (mediaPlayers.containsKey(inPath))
		//	return mediaPlayers.get(inPath).isComplete;
		//return true;
	}

	public static void setMusicTransform(String inPath, double inVolLeft, double inVolRight)
	{
		if (mediaPlayer != null) {
			mediaPlayer.setVolume((float)inVolLeft, (float)inVolRight);
		}
			
		//if (mediaPlayers.containsKey(inPath))
		//	mediaPlayers.get(inPath).setVolume((float)inVolLeft, (float)inVolRight);
	}
}
	