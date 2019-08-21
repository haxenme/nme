/*
 * Copyright (C) 2008 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.haxe.nme;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;
import android.util.Log;
import android.view.InputDevice;
import android.widget.TextView;
import android.widget.EditText;
import android.text.InputType;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.app.Activity;
import android.graphics.PixelFormat;
import android.view.View;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;
import javax.microedition.khronos.opengles.GL10;

import java.util.TimerTask;
import java.util.concurrent.Semaphore;

/**
 * A simple GLSurfaceView sub-class that demonstrate how to perform
 * OpenGL ES 2.0 rendering into a GL Surface. Note the following important
 * details:
 *
 * - The class must use a custom context factory to enable 2.0 rendering.
 *   See ContextFactory class definition below.
 *
 * - The class must use a custom EGLConfigChooser to be able to select
 *   an EGLConfig that supports 2.0. This is done by providing a config
 *   specification to eglChooseConfig() that has the attribute
 *   EGL10.ELG_RENDERABLE_TYPE containing the EGL_OPENGL_ES2_BIT flag
    *   set. See ConfigChooser class definition below.
 *
 * - The class must select the surface's format, then choose an EGLConfig
 *   that matches it exactly (with regards to red/green/blue/alpha channels
 *   bit depths). Failure to do so would result in an EGL_BAD_MATCH error.
 */
class MainView extends GLSurfaceView {

   GameActivity mActivity;
   boolean  translucent;
   static MainView mRefreshView;

   boolean isPollImminent;
   boolean deactivated;
   boolean onPaused;
   Runnable pollMe;
   TimerTask pendingTimer;
   Semaphore pendingTimerSemaphore;
   boolean renderPending = false;


   
  //private InputDevice device;
    public MainView(Context context,GameActivity inActivity, boolean inTranslucent)
    {
       super(context);

       isPollImminent = false;
       pendingTimerSemaphore = new Semaphore(1,true);
       final MainView me = this;
       pollMe = new Runnable() {
           @Override public void run() { me.onPollHX(); }
       };

       translucent = inTranslucent;
       getHolder().setFormat(
          translucent ? PixelFormat.TRANSLUCENT : PixelFormat.OPAQUE );


        setZOrderMediaOverlay(true);

        //setLayerType(View.LAYER_TYPE_NONE, null);
        //setLayerType(View.LAYER_TYPE_SOFTWARE, null);
        //setLayerType(View.LAYER_TYPE_HARDWARE, null);

        EGL10 egl = (EGL10)EGLContext.getEGL();
        EGLDisplay display = egl.eglGetDisplay(EGL10.EGL_DEFAULT_DISPLAY);
        int[] version = new int[2];
        egl.eglInitialize(display, version);
        EGLConfig[] v2_configs = new EGLConfig[1];
        int[] num_config = new int[1];
        int[] attrs = { EGL10.EGL_RENDERABLE_TYPE, 4 /*EGL_OPENGL_ES2_BIT*/, EGL10.EGL_NONE };
        egl.eglChooseConfig(display, attrs, v2_configs, 1, num_config);
        //Log.v("EGL","v2 configs : " + num_config[0]);
        if (num_config[0]!=1)
           Log.e("VIEW", "OpenglES 2.0 apparently not supported.");
        else
           Log.e("VIEW", "Using OpenglES 2.0");

        final int renderType =  0x04;
        setEGLContextClientVersion(2);


        setEGLConfigChooser(new EGLConfigChooser()
        {
             public EGLConfig chooseConfig (EGL10 egl, EGLDisplay display)
             {
                Log.v("EGL","Choose config (2) " + translucent);
                int alpha = translucent ? 8 : 0;
                int depth = ::if WIN_DEPTH_BUFFER:: 16 ::else:: 0 ::end::;
                int stencil = ::if WIN_STENCIL_BUFFER:: 8 ::else:: 0 ::end::;

                EGLConfig[] configs = new EGLConfig[1];
                int[] num_config = new int[1];


                // Try as specified - aa
                if (::WIN_ANTIALIASING:: >= 1)
                {
                   int[] attrs = { EGL10.EGL_DEPTH_SIZE, depth,
                                   EGL10.EGL_STENCIL_SIZE, stencil,
                                   EGL10.EGL_ALPHA_SIZE, alpha,
                                   EGL10.EGL_SAMPLE_BUFFERS, 1 /* true */,
                                   EGL10.EGL_SAMPLES, ::WIN_ANTIALIASING::,
                                   EGL10.EGL_RENDERABLE_TYPE, renderType,
                                   EGL10.EGL_NONE };

                   egl.eglChooseConfig(display, attrs, configs, 1, num_config);
                   Log.v("EGL","Match AA=::WIN_ANTIALIASING::, depth + stencil : " + num_config[0]);

                   if (num_config[0]==1)
                      return configs[0];

                   // Try with just 2 specified - aa
                   if (::WIN_ANTIALIASING:: > 2)
                   {
                      int[] attrs_aa2 = { EGL10.EGL_DEPTH_SIZE, depth,
                                      EGL10.EGL_STENCIL_SIZE, stencil,
                                      EGL10.EGL_ALPHA_SIZE, alpha,
                                      EGL10.EGL_SAMPLE_BUFFERS, 1 /* true */,
                                      EGL10.EGL_SAMPLES, 2,
                                      EGL10.EGL_RENDERABLE_TYPE, renderType,
                                      EGL10.EGL_NONE };
   
                      egl.eglChooseConfig(display, attrs_aa2, configs, 1, num_config);
                      Log.v("EGL","Match AA=2, depth + stencil : " + num_config[0]);

                      if (num_config[0]==1)
                        return configs[0];
                   }

                   // No normal multisampling config was found. Try to create a
                   // converage multisampling configuration, for the nVidia Tegra2.
                   // See the EGL_NV_coverage_sample documentation.

                   final int EGL_COVERAGE_BUFFERS_NV = 0x30E0;
                   final int EGL_COVERAGE_SAMPLES_NV = 0x30E1;

                   int[] attrs_aanv = { EGL10.EGL_DEPTH_SIZE, depth,
                                      EGL10.EGL_STENCIL_SIZE, stencil,
                                      EGL10.EGL_ALPHA_SIZE, alpha,
                                      EGL_COVERAGE_BUFFERS_NV, 1 /* true */,
                                      EGL_COVERAGE_SAMPLES_NV, 2,  // always 5 in practice on tegra 2
                                      EGL10.EGL_RENDERABLE_TYPE, renderType,
                                      EGL10.EGL_NONE };

                   egl.eglChooseConfig(display, attrs_aanv, configs, 1, num_config);
                   Log.v("EGL","Match AANV, depth + stencil : " + num_config[0]);

                   if (num_config[0]==1)
                       return configs[0];
                }

                // Try just specifying just depth and stencil
                int[] attrs1 = { EGL10.EGL_DEPTH_SIZE, depth,
                                EGL10.EGL_STENCIL_SIZE, stencil,
                                EGL10.EGL_ALPHA_SIZE, alpha,
                                EGL10.EGL_RENDERABLE_TYPE, renderType,
                                EGL10.EGL_NONE };

                egl.eglChooseConfig(display, attrs1, configs, 1, num_config);
                Log.v("EGL","Matched depth + stencil : " + num_config[0] + "(" + alpha + ")" );
                if (num_config[0]==1)
                   return configs[0];

                // Just give me whatever you've got
                int[] attrs2 = { EGL10.EGL_NONE };
                egl.eglChooseConfig(display, attrs2, configs, 1, num_config);
                if (num_config[0]==1)
                   return configs[0];
                Log.v("EGL","Matched any : " + num_config[0]);

                return null;
             }
        });
        mActivity = inActivity;
        mRefreshView = this;
        setFocusable(true);
        setFocusableInTouchMode(true);
        setRenderer(new Renderer(this));
        setRenderMode(GLSurfaceView.RENDERMODE_WHEN_DIRTY);
       //Log.v("VIEW", "present on system: " + InputDevice.getDeviceIds());
    }

   public void checkZOrder()
   {
      setZOrderMediaOverlay(true);
   }

   static final int etTouchBegin = 15;
   static final int etTouchMove  = 16;
   static final int etTouchEnd   = 17;
   static final int etTouchTap   = 18;

   static final int resTerminate = -1;
   java.util.Timer mTimer = new java.util.Timer();
   int mTimerID = 0;


   public void setTranslucent(boolean inTranslucent)
   {
      if (inTranslucent!=translucent)
      {
         translucent = inTranslucent;

         // Seems to be some funky timing issue - but three times is a charm?
         onPause();
         getHolder().setFormat(
             inTranslucent ? PixelFormat.TRANSLUCENT : PixelFormat.OPAQUE );

         getHolder().setFormat(
             !inTranslucent ? PixelFormat.TRANSLUCENT : PixelFormat.OPAQUE );

         getHolder().setFormat(
             inTranslucent ? PixelFormat.TRANSLUCENT : PixelFormat.OPAQUE );
         onResume();

         setZOrderMediaOverlay(true);
      }
   }

   // Haxe thread
   public void HandleResult(int inCode)
   {
       if (inCode==resTerminate)
       {
          //Log.v("VIEW","Terminate Request.");
          mActivity.onNMEFinish();
          return;
       }


       double wake = NME.getNextWake();
       int delayMs = (int)(wake * 1000);

       if (renderPending && delayMs<5)
          delayMs = 5;

       if (delayMs<=1)
          queuePoll();
       else
       {
          pendingTimerSemaphore.acquireUninterruptibly();
          
          if (pendingTimer!=null)
             pendingTimer.cancel();

          final MainView me = this;
          pendingTimer = new TimerTask() {
              @Override public void run() {
                 me.queuePoll();
              }
          };

          mTimer.schedule(pendingTimer,delayMs);

          pendingTimerSemaphore.release();
       }
   }


   // Haxe thread...
   void onPollHX()
   {
      isPollImminent = false;
      HandleResult( NME.onPoll() );
   }

   void sendActivity(final int inActivity)
   {
      queueEvent(new Runnable(){ public void run() { NME.onActivity(inActivity); } } );
   }

   // Gui (timer) thread
   void queuePoll()
   {
      if (!isPollImminent)
      {
         isPollImminent = true;
         queueEvent(pollMe);
      }
   }


   // Called diectly by NME...
   static public void renderNow()
   {
     //Log.v("VIEW","renderNow!!!");
     mRefreshView.renderPending = true;
     mRefreshView.requestRender();
   }
   
       public boolean onGenericMotionEvent(MotionEvent event) {
        if ((event.getSource() & InputDevice.SOURCE_CLASS_JOYSTICK) != 0) {
            if (event.getAction() == MotionEvent.ACTION_MOVE) {
                //TODO: process the joystick movement...
                return true;
            }
        }
        if ((event.getSource() & InputDevice.SOURCE_CLASS_POINTER) != 0) {
            switch (event.getAction()) {
                case MotionEvent.ACTION_HOVER_MOVE:
                    //TODO process the mouse hover movement...
                    return true;
                case MotionEvent.ACTION_HOVER_EXIT:
                    //TODO process the mouse exit ..
                    return true;
                case MotionEvent.ACTION_SCROLL:
                    final MainView me = this;
                    final float x = event.getRawX();
                    final float y = event.getRawY();
                    //previous behavior in nme was 3 for down, 4 for up
                    final int event_dir = event.getAxisValue(MotionEvent.AXIS_VSCROLL) < 0.0f ? 4 : 3;
                    queueEvent(new Runnable(){
                        public void run() { me.HandleResult(NME.onMouseWheel(x,y,event_dir) ); }
                    });
                    return true;
            }
        }
        return super.onGenericMotionEvent(event);
    }

   @Override
   public void onPause () {
       Log.v("NME","onPause");
       deactivated = true;
       
       super.onPause(); //Pause GL Thread

       pendingTimerSemaphore.acquireUninterruptibly();
       if (pendingTimer != null) { //Pause the Haxe Thread
         pendingTimer.cancel();
       }
       pendingTimerSemaphore.release();
   }

   @Override
   public void onResume () {
       Log.v("NME","onResume");
       deactivated = false;
       onPaused = false;
       super.onResume();
   }

   @Override
   public boolean onTouchEvent(final MotionEvent ev)
   {
       final MainView me = this;

       final int action = ev.getAction();

       int type = -1;

       switch (action & MotionEvent.ACTION_MASK)
       {
          case MotionEvent.ACTION_DOWN: type = etTouchBegin; break;
          case MotionEvent.ACTION_POINTER_DOWN: type = etTouchBegin; break;
          case MotionEvent.ACTION_MOVE: type = etTouchMove; break;
          case MotionEvent.ACTION_UP: type = etTouchEnd; break;
          case MotionEvent.ACTION_POINTER_UP: type = etTouchEnd; break;
          case MotionEvent.ACTION_CANCEL: type = etTouchEnd; break;
       }

       //Log.e("VIEW","Actions : " + action );

       // This is actually index, not id....
       int idx = (action & MotionEvent.ACTION_POINTER_ID_MASK) >>
                       (MotionEvent.ACTION_POINTER_ID_SHIFT);

       final int t = type;
       //if (type!=etTouchMove)
       //   Log.e("VIEW","onTouchEvent " + ev.toString() );

       for(int i = 0; i < ev.getPointerCount(); i++)
       {
           // Log.e("VIEW","onTouchEvent " + type + " x " + ev.getPointerCount() );
           final int id = ev.getPointerId(i);
           final float x = ev.getX(i);
           final float y = ev.getY(i);
           final float sizeX = ev.getSize(i);
           final float sizeY = ev.getSize(i);
           //if (type!=etTouchMove)
              //Log.e("VIEW","  " + i + "]  type=" + t + " id="+ id + " idx="+ idx +" " + x + ", "+ y + "," + sizeX + "," + sizeY);
           if (type==etTouchMove || i==idx)
           {
              queueEvent(new Runnable(){
                 public void run() { me.HandleResult( NME.onTouch(t,x,y,id,sizeX,sizeY) ); }
                 });
           }
       }
       return true;
    }


    @Override
    public boolean onTrackballEvent(final MotionEvent ev)
    {
       final MainView me = this;
       queueEvent(new Runnable(){
          public void run() {
          float x = ev.getX();
          float y = ev.getY();
          me.HandleResult( NME.onTrackball(x,y) );
       }});
       return false;
    }

    public static int translateKey(int inCode, KeyEvent event,boolean inTranslateUnicode)
    {
       switch(inCode)
       {
          case KeyEvent.KEYCODE_DPAD_CENTER: return 13; /* Fake ENTER */
          case KeyEvent.KEYCODE_DPAD_LEFT: return 37;
          case KeyEvent.KEYCODE_DPAD_RIGHT: return 39;
          case KeyEvent.KEYCODE_DPAD_UP: return 38;
          case KeyEvent.KEYCODE_DPAD_DOWN: return 40;
          case KeyEvent.KEYCODE_BACK: return 27; /* Fake Escape */
          case KeyEvent.KEYCODE_MENU: return 0x01000012; /* Fake MENU */

          case KeyEvent.KEYCODE_ENTER: return 13; /* Fake MENU */

          case KeyEvent.KEYCODE_DEL: return inTranslateUnicode ? 8 : 0;//8;
       }

       if (inTranslateUnicode)
       {
          int result = event.getUnicodeChar( event.getMetaState() );
          if (result==android.view.KeyCharacterMap.COMBINING_ACCENT)
          {
             //TODO:
             return 0;
          }
          return result;
       }

       return 0;
    }

    @Override
    public boolean onKeyDown(final int inKeyCode, KeyEvent event)
    {
         // Log.e("VIEW","onKeyDown " + inKeyCode);
          Log.v("VIEW", "device of event is " + event.getDeviceId());
         final MainView me = this;
         final int keyCode = translateKey(inKeyCode,event,true);
         // Log.v("VIEW","onKeyDown " + inKeyCode + "->" + keyCode);
         final int deviceId = event.getDeviceId();
         if (keyCode!=0) {
             queueEvent(new Runnable() {
                 // This method will be called on the rendering thread:
                 public void run() {
                     me.HandleResult(NME.onKeyChange(keyCode,keyCode,true,true));
                     me.HandleResult(NME.onJoyChange(deviceId,keyCode,true));
                 }});
             return true;
         }
         return super.onKeyDown(inKeyCode, event);
     }


    @Override
    public boolean onKeyUp(final int inKeyCode, KeyEvent event)
    {
         //Log.v("VIEW","onKeyUp " + inKeyCode);
          Log.v("VIEW", "device of event is " + event.getDeviceId());
         final MainView me = this;
         final int keyCode = translateKey(inKeyCode,event,true);
         // Log.v("VIEW","onKeyUp " + inKeyCode + "->" + keyCode);
         final int deviceId = event.getDeviceId();
         if (keyCode!=0)
         {
             queueEvent(new Runnable() {
                 // This method will be called on the rendering thread:
                 public void run() {
                     me.HandleResult(NME.onKeyChange(keyCode,keyCode,false,false));
                     me.HandleResult(NME.onJoyChange(deviceId,keyCode,false));
                 }});
             return true;
         }
         return super.onKeyDown(inKeyCode, event);
     }


    private static class Renderer implements GLSurfaceView.Renderer
    {
        MainView mMainView;

        public Renderer(MainView inView) { mMainView = inView; }

        public void onDrawFrame(GL10 gl)
        {
            if(mMainView.deactivated) {
                if(mMainView.onPaused) {
                    mMainView.onPaused = true;
                    mMainView.onPause();
                }
            }
            else {
                mMainView.renderPending = false;
                mMainView.HandleResult( NME.onRender() );
                Sound.checkSoundCompletion();
            }
        }

        public void onSurfaceChanged(GL10 gl, int width, int height)
        {
           ::if (DEBUG)::
           Log.v("VIEW","onSurfaceChanged " + width +"," + height);
           Log.v("VIEW", "Thread = " + java.lang.Thread.currentThread().getId() );
           ::end::

           mMainView.HandleResult( NME.onResize(width,height) );
           GameActivity a = GameActivity.activity;
           if (a!=null)
              GameActivity.activity.onResizeAsync(width,height);
        }

        public void onSurfaceCreated(GL10 gl, EGLConfig config)
        {
           mMainView.isPollImminent = false;
           mMainView.renderPending = false;
           ::if (DEBUG)::
           Log.v("VIEW","onSurfaceCreated");
           Log.v("VIEW", "Thread = " + java.lang.Thread.currentThread().getId() );
           ::end::
           mMainView.HandleResult( NME.onContextLost() );
        }
    }
}



