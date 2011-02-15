package org.haxe.nme;


import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.view.Window;
import android.util.Log;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;

public class GameActivity extends Activity {

    MainView mView;
    static AssetManager mAssets;

    protected void onCreate(Bundle state) {
        super.onCreate(state);
        mAssets = getAssets();
       //getResources().getAssets();

       //java.io.File file =  android.os.Environment.getDataDirectory();

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
          if (inFilename=="::id::")
             id = ::APP_PACKAGE::.R.raw.::flatName::;
          ::end::
       ::end::
/*
       if (id>0)
       {
          int index = 
          mSoundManager.addSound(1,id);
       }

 */
       return -1;
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

