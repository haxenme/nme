package org.haxe.nme;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;


public class GameActivity extends Activity {

    MainView mView;

    protected void onCreate(Bundle state,String inClassName) {
        super.onCreate(state);

       //java.io.File file =  android.os.Environment.getDataDirectory();

        org.haxe.HXCPP.run(inClassName);
        
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

