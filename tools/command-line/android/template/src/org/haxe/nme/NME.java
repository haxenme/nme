package org.haxe.nme;

// Wrapper for native library

public class NME {

     static {
         System.loadLibrary("nme");
     }

     public static final int ACTIVATE   = 1;
     public static final int DEACTIVATE = 2;
     public static final int DESTROY    = 3;

     public static native int onTouch(int type, float x, float y, int id);
     public static native int onResize(int width, int height);
     public static native int onTrackball(float x,float y);
     public static native int onKeyChange(int inCode, boolean inIsDown);
     public static native int onRender();
     public static native int onPoll();
     public static native double getNextWake();
     public static native int onActivity(int inState);
     public static native void onCallback(long inHandle);
     public static native Object callObjectFunction(long inHandle,String function, Object[] args);
     public static native double callNumericFunction(long inHandle,String function, Object[] args);
}
