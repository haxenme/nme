package org.haxe.nme;


import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.view.Window;
import android.util.Log;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;
import android.content.Context;
import android.media.SoundPool;

public class GameActivity extends Activity {

    MainView mView;
    static AssetManager mAssets;
    static SoundPool mSoundPool;
	 static Context mContext;

    protected void onCreate(Bundle state) {
        super.onCreate(state);
		  mContext = this;
        mAssets = getAssets();
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
       ::foreach assets:: ::if (type=="sound")::
          if (inFilename.equals("::id::"))
             id = ::APP_PACKAGE::.R.raw.::flatName::;
          ::end::
       ::end::

       Log.e("GameActivity","Get sound handle ------------------>" + inFilename + " = " + id);
       if (id>0)
       {
          int index = mSoundPool.load(mContext,id,1);
          Log.e("GameActivity","Loaded index" + index);
			 return index;
       }

       return -1;
    }

    static public int playSound(int inSoundID, double inVolLeft, double inVolRight, int inLoop)
	 {
       Log.e("GameActivity","PlaySound ------------------>" + inSoundID);
	    return mSoundPool.play(inSoundID,(float)inVolLeft,(float)inVolRight, 1, inLoop, 1.0f);
	 }

    static public void playMusic(String inFilename)
    {
    }

    @Override protected void onPause() {
        super.onPause();
        mView.onPause();
    }

    @Override protected void onResume() {
        super.onResume();
        mView.onResume();
    }
}

