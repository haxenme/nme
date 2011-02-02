package org.haxe.nme;


import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.view.Window;

public class GameActivity extends Activity {

    MainView mView;

    protected void onCreate(Bundle state) {
        super.onCreate(state);

       //java.io.File file =  android.os.Environment.getDataDirectory();

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, 
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        
        // Pre-load these, so the c++ knows where to find them
        System.loadLibrary("std");
        System.loadLibrary("zlib");
        System.loadLibrary("regexp");
        System.loadLibrary("nme");
        org.haxe.HXCPP.run("AndroidMain");
        
        mView = new MainView(getApplication(),this);

	setContentView(mView);
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

