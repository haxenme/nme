package org.haxe.nme;

import android.util.Log;
import android.view.Surface;
import android.graphics.SurfaceTexture;
import android.opengl.Matrix;
import android.hardware.Camera;
import java.lang.Math;
import java.util.List;
import java.io.IOException;

class CameraInterface implements SurfaceTexture.OnFrameAvailableListener
{
   static final String TAG = "CameraInterface";
   Camera camera;
   int    cameraId;
   int    previewWidth;
   int    previewHeight;
   int    cameraTextureId;
   boolean textureDirty;
   static SurfaceTexture  surfaceTexture;
   Camera.Parameters parms;


   public CameraInterface( )
   {
   }

   public void open( int inTextureId, boolean inPreferFront, int width, int height, int milliFps)
   {
      if (camera!=null)
      {
         Log.e(TAG, "CameraInterface - already open");
         return;
      }
      textureDirty = false;
   
      Camera.CameraInfo info = new Camera.CameraInfo();

      int cameraCount = Camera.getNumberOfCameras();
      int backupId = -1;
      for(int i=0; i<cameraCount; i++)
      {
         Camera.getCameraInfo(i, info);
         if ( (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) == inPreferFront )
         {
            camera = Camera.open(i);
            if (camera!=null)
            {
               cameraId = i;
               break;
            }
         }
         else if (backupId<0)
            backupId = i;
      }

      if (camera==null && backupId>=0)
      {
         camera = Camera.open(backupId);
         if (camera!=null)
            cameraId = backupId;
      }

      if (camera == null)
         throw new RuntimeException("Could not open camera");

      parms = camera.getParameters();

      Camera.Size best = null;
      double bestScore = 0;
      for(Camera.Size size : parms.getSupportedPreviewSizes())
      {
         double score = Math.abs(size.width-width) + Math.abs(size.height-height) + 
                Math.abs( Math.log( (double)size.width*height / (double)(size.height*width) ) );
         if (best==null || bestScore>score)
         {
            best = size;
            bestScore = score;
         }
      }

      if (best==null)
         throw new RuntimeException("Could not find preview size " + width + "x" + height);

      previewWidth = best.width;
      previewHeight = best.height;
      parms.setPreviewSize(previewWidth, previewHeight);


      List<int[]> supportedFps = parms.getSupportedPreviewFpsRange();

      boolean set = false;
      int range0 = 0;
      int range1 = 0;
      for (int[] entry : supportedFps)
      {
          if ((entry[0] == milliFps) && (entry[0] == milliFps))
          {
              parms.setPreviewFpsRange(range0 = entry[0], range1 = entry[1]);
              set = true;
              break;
          }
      }
      if (!set)
         for (int[] entry : supportedFps)
         {
             if ((entry[0]<=milliFps) && (entry[0]>=milliFps))
             {
                 parms.setPreviewFpsRange(range0 = entry[0], range1 = entry[1]);
                 break;
             }
         }

      cameraTextureId = inTextureId;
      parms.setRecordingHint(true);
      camera.setParameters(parms);
      Log.i(TAG, "Creates camera preview " + previewWidth + "x" + previewHeight + " @" + (range0*0.001) + "..." + (range1*0.001) + "fps");

       startPreview();
   }


   public void startPreview( )
   {
      if (surfaceTexture==null)
      {
         surfaceTexture = new SurfaceTexture(cameraTextureId);
         surfaceTexture.setOnFrameAvailableListener(this);

         try {
             camera.setPreviewTexture(surfaceTexture);
         } catch (IOException ioe) {
             throw new RuntimeException(ioe);
         }
      }
      textureDirty = true;
      camera.startPreview();
   }

   public void close()
   {
      if (surfaceTexture!=null)
      {
         surfaceTexture.setOnFrameAvailableListener(null);
         surfaceTexture.release();
         surfaceTexture = null;
      }
      if (camera != null)
      {
         camera.stopPreview();
         camera.release();
         camera = null;
      }
   }

   void getTextureTransform(int [] outSize, float [] outMatrix)
   {
      outSize[0] = previewWidth;
      outSize[1] = previewHeight;
      if (surfaceTexture!=null)
         surfaceTexture.getTransformMatrix(outMatrix);
   }

   public boolean getNextTexture(float [] outMatrix)
   {
      if (surfaceTexture!=null && textureDirty)
      {
         surfaceTexture.updateTexImage();
         return true;
      }
      return false;
   }


   // Called from foreign thread
   public void onFrameAvailable(SurfaceTexture surfaceTexture)
   {
      textureDirty = true;
      // TODO - callback
   }

}

