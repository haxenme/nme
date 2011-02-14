package org.haxe.nme;

// Wrapper for native library

public class NME {

     static {
         System.loadLibrary("nme");
     }

     public static native int onTouch(int type, float x, float y, int id);
     public static native int onResize(int width, int height);
     public static native int onTrackball(float x,float y);
     public static native int onKeyChange(int inCode, boolean inIsDown);
     public static native int onRender();
     public static native int onPoll();
     public static native double getNextWake();
}
