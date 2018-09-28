package org.haxe;

import android.util.Log;

// Wrapper for native library

public class HXCPP {
     static boolean mInit = false;

     static public void run(String inClassName) {
         ::if (DEBUG):: Log.v("HXCPP","Boot " + inClassName); ::end::
         System.loadLibrary(inClassName);
         ::if (DEBUG):: Log.v("HXCPP","Boot " + inClassName + " done"); ::end::

         if (!mInit)
         {
            mInit = true;
            main();
         }
     }
    
     public static native void main(); 
}

