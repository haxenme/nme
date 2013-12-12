package org.haxe.nme;


import android.app.Activity;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.Window;
import android.widget.FrameLayout;
import android.view.ViewGroup;
import android.view.Gravity;
import android.view.ViewGroup.LayoutParams;
import android.widget.RelativeLayout;
import android.view.WindowManager;
import android.widget.VideoView;
import android.net.Uri;
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.Math;
import java.util.HashMap;
import java.util.Locale;
import android.media.MediaPlayer;


public class NMEVideoView extends VideoView implements
        MediaPlayer.OnCompletionListener,
        MediaPlayer.OnErrorListener,
        MediaPlayer.OnInfoListener,
        MediaPlayer.OnPreparedListener
{
   static final String TAG = "NMEVideoView";
   boolean vpSet = false;
   HaxeObject handler;
   public int videoWidth = 0;
   public int videoHeight = 0;
   double duration = 0.0;
   float  volume = 1.0f;
   MediaPlayer mPreparedMp = null;
   GameActivity activity;
   public String   playingUrl;

   boolean susPlaying = false;
   int susPosition = 0;

   public NMEVideoView(GameActivity inActiviy,HaxeObject inHandler)
   {
      super(inActiviy);
      handler = inHandler;
      activity = inActiviy;

      setOnCompletionListener(this);
      setOnErrorListener(this);
      // API 17 - setOnInfoListener(this);
      setOnPreparedListener(this);
   }

   public void nmeSuspend()
   {
      Log.d(TAG,"nemSuspend");
      susPlaying = isPlaying();
      susPosition = getCurrentPosition();
      mPreparedMp = null;
      suspend();
   }

   public void nmeResume()
   {
      Log.d(TAG,"nmeResume");
      resume();
      if (susPlaying)
         start();
      seekTo(susPosition);
   }


   public void onCompletion(MediaPlayer mp)
   {
      Log.d(TAG,"onComplete!");
      sendStatusCode(0);
   }

   public boolean onError(MediaPlayer mp, int what, int extra)
   {
      Log.d(TAG,"onError!");
      return false;
   }

   public boolean onInfo(MediaPlayer mp, int what, int extra)
   {
      Log.d(TAG,"onInfo!");
      return true;
   }

   public void onPrepared(MediaPlayer mp)
   {
      Log.d(TAG,"onPrepared");
      mPreparedMp = mp;
      mPreparedMp.setVolume(volume, volume);
      videoWidth = mp.getVideoWidth();
      videoHeight = mp.getVideoHeight();

 

      Log.d(TAG," size: " + videoWidth + "x" + videoHeight );
      activity.setVideoLayout();
      sendMetaDataAsync();
   }

   public void setVolumeSync(double inVal)
   {
      volume = (float)inVal;
      if (mPreparedMp!=null)
         mPreparedMp.setVolume(volume, volume);
   }

   public void playSync(String inUrl,boolean inStart)
   {
      playingUrl = inUrl;
      Uri uri = Uri.parse(inUrl);
      videoWidth = videoHeight = 0;
      mPreparedMp = null;
      setVideoURI(uri);
      if (inStart)
         start();
   }

   public static void nmeSeek(double inTo)
   {
      Log.d(TAG,"seek " + inTo);
      NMEVideoView vv = GameActivity.activity.mVideoView;
      if (vv!=null)
         vv.seekTo((int)(inTo*1000.0));
   }

   public static void nmeSetVolume(final double inTo)
   {
      final GameActivity a = GameActivity.activity;
      a.queueRunnable( new Runnable() { @Override public void run() {
          if (a.mVideoView!=null)
          {
             a.mVideoView.setVolumeSync(inTo);
          } } } );
   }


   public static void nmeSetViewport(final double inX, final double inY, final double inW, final double inH)
   {
      final GameActivity a = GameActivity.activity;
      a.queueRunnable( new Runnable() { @Override public void run() {
          if (a.mVideoView!=null)
          {
             a.setVideoViewport(inX,inY,inW,inH);
          } } } );
   }


   public static void nmePlay(final String inUrl, final double inStart, final double inLen)
   {
      Log.d(TAG,"play " + inUrl);

      final GameActivity a = GameActivity.activity;
      a.queueRunnable( new Runnable() { @Override public void run() {
          if (a.mVideoView!=null)
          {
             a.mVideoView.playSync(inUrl,true);
          } } } );
   }


   public static void nmeStart()
   {
      Log.d(TAG,"start");

      final GameActivity a = GameActivity.activity;
      a.queueRunnable( new Runnable() { @Override public void run() {
          if (a.mVideoView!=null)
             a.mVideoView.start();
         } });
   }

   public static void nmeStop()
   {
      Log.d(TAG,"stop");

      final GameActivity a = GameActivity.activity;
      a.queueRunnable( new Runnable() { @Override public void run() {
          if (a.mVideoView!=null)
             a.mVideoView.stopPlayback();
         } });
   }

   public static void nmePause()
   {
      Log.d(TAG,"pause");

      final GameActivity a = GameActivity.activity;
      a.queueRunnable( new Runnable() { @Override public void run() {
          if (a.mVideoView!=null)
             a.mVideoView.pause();
         } });
   }

   public static double nmeGetDuration()
   {
      VideoView vv = GameActivity.activity.mVideoView;
      if (vv!=null)
      {
         int duration =  vv.getDuration();
         if (duration>0)
            return duration * 0.001;
      }
      return 0.0;
   }

   public static double nmeGetBuffered()
   {
      VideoView vv = GameActivity.activity.mVideoView;
      if (vv!=null)
         return vv.getBufferPercentage();
      return 0.0;

   }

   public static double nmeGetPosition()
   {
      VideoView vv = GameActivity.activity.mVideoView;
      if (vv!=null)
         return vv.getCurrentPosition() * 0.001;
      return 0.0;
   }

   public void sendMetaDataSync()
   {
      double duration = getDuration();
      duration = duration<0 ? 0 : duration*0.001;
      handler.call3("_native_set_data", videoWidth, videoHeight, duration );
   }

   void sendMetaDataAsync()
   {
      final NMEVideoView me = this;
      GameActivity.activity.getMainView().queueEvent(new Runnable(){ public void run() {
         me.sendMetaDataSync();
       }});
   }

   void sendStatusCode(final int inCode)
   {
      final HaxeObject h = handler;
      GameActivity.activity.getMainView().queueEvent(new Runnable(){ public void run() {
         h.call1("_native_play_status", inCode );
       }});
   }



   @Override
   protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec)
   {
      int widthSpecMode = MeasureSpec.getMode(widthMeasureSpec);
      int widthSpecSize = MeasureSpec.getSize(widthMeasureSpec);
      int heightSpecMode = MeasureSpec.getMode(heightMeasureSpec);
      int heightSpecSize = MeasureSpec.getSize(heightMeasureSpec);

      Log.d(TAG,"Measure Video:" + widthSpecSize + "," + heightSpecSize);
      super.onMeasure(widthMeasureSpec,heightMeasureSpec);
      Log.d(TAG,"  ->" + getMeasuredWidth() + "," + getMeasuredHeight() );
   }
}


