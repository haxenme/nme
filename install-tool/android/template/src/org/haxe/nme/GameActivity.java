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
        Log.e("GameActivity","getResource " + inResource);

           try {
                  byte [] result = new byte[0];

                  java.io.InputStream inputStream = mAssets.open(inResource,AssetManager.ACCESS_BUFFER);
                  byte [] buffer = new byte[1024];
                  while(true)
                  {
                     int read = inputStream.read(buffer,0,1024);
                     if (read<=0)
                        break;
                     byte [] total = java.util.Arrays.copyOf(result, result.length + read);
                     System.arraycopy(buffer, 0, total, result.length, read);
                     result = total;
                     if (read<1024)
                        break;
                  }
                  inputStream.close();

                  return result;
           } catch (java.io.IOException e) {
               Log.e("GameActivity",e.toString());
           }

               Log.e("GameActivity","No resource");
        
           return null;
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

