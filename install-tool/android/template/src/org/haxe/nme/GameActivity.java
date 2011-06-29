package org.haxe.nme;


import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.view.Window;
import android.util.Log;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;
import android.content.Context;
import android.media.SoundPool;
import android.media.MediaPlayer;
import android.net.Uri;

public class GameActivity extends Activity {

    MainView mView;
    static AssetManager mAssets;
    static SoundPool mSoundPool;
	 static Context mContext;
	 static MediaPlayer mMediaPlayer = null;
	 static GameActivity activity;

    protected void onCreate(Bundle state) {
        super.onCreate(state);
		activity=this;
		  mContext = this;
        mAssets = getAssets();
        setVolumeControlStream(android.media.AudioManager.STREAM_MUSIC);  
		  mSoundPool = new SoundPool(8,android.media.AudioManager.STREAM_MUSIC,0);
       //getResources().getAssets();

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, 
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        
        // Pre-load these, so the c++ knows where to find them
        ::foreach ndlls::
           System.loadLibrary("::name::");
         ::end::
        org.haxe.HXCPP.run("ApplicationMain");
        
        mView = new MainView(getApplication(),this);

        setContentView(mView);
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
               Log.e("GameActivity",e.toString());
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

    static public void playMusic(String inFilename)
    {
    }

    @Override protected void onPause() {
        super.onPause();
        mView.onPause();
        NME.onActivity(NME.DEACTIVATE);
        if (mMediaPlayer!=null)
           mMediaPlayer.pause();
    }

    @Override protected void onResume() {
        super.onResume();
        mView.onResume();
        if (mMediaPlayer!=null)
           mMediaPlayer.start();
        NME.onActivity(NME.ACTIVATE);
    }
	
	@Override protected void onDestroy() {
      NME.onActivity(NME.DESTROY);
		activity=null;
      super.onDestroy();
	}
}

