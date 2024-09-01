package org.haxe.nme;

import android.util.Log;
// Wrapper for native library

public class NME {

     static {
         ::if (DEBUG):: Log.v("HXCPP","Boot nme.."); ::end::
         ::if (!STATIC_NME)::System.loadLibrary("nme");::end::
         ::if (DEBUG):: Log.v("HXCPP","Boot nme done"); ::end::
     }

     public static final int ACTIVATE   = 1;
     public static final int DEACTIVATE = 2;
     public static final int DESTROY    = 3;

     public static native int onDeviceOrientationUpdate(int orientation);
     public static native int onNormalOrientationFound(int orientation);
     public static native int onOrientationUpdate(float x, float y, float z);
     public static native int onAccelerate(float x, float y, float z);
     public static native int onMouseWheel(float x, float y, int inEventDir);
     public static native int onTouch(int type, float x, float y, int id, float sizeX, float sizeY);
     public static native int onResize(int width, int height);
     public static native int onContextLost();
     public static native int onTrackball(float x,float y);
     public static native int onJoyChange(int inDeviceID, int inCode, boolean inIsDown);
     public static native int onKeyChange(int inKeyCode, int inCharCode, boolean inIsDown, boolean isChar);
     public static native int onText(String inNewText, int inReplacePos, int inReplaceLength);
     public static native int onTextSelect( int inReplacePos, int inReplaceLength);
     public static native int onRender();
     public static native int onPoll();
     public static native int setLaunchAppLink(String url);
     public static native int onAppLink(String url);
     public static native double getNextWake();
     public static native int onActivity(int inState);
     public static native void onCallback(long inHandle);
     public static native Object callObjectFunction(long inHandle,String function, Object[] args);
     public static native double callNumericFunction(long inHandle,String function, Object[] args);
     public static native void releaseReference(long inHandle);
     public static native void onPermission(String permission, int inResult);
}
