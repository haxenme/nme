import nme.display.Sprite;
import nme.net.NetStream;
import nme.net.NetConnection;
import nme.events.StageVideoEvent;

import nme.events.AsyncErrorEvent;
import nme.events.NetStatusEvent;
import nme.events.MouseEvent;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.geom.Matrix;
import nme.media.SoundTransform;

/*
The following steps summarize how to use a StageVideo object to play a video:

Attach a NetStream object using StageVideo.attachNetStream().
Play the video using NetStream.play().
Listen for the StageVideoEvent.RENDER_STATE event on the StageVideo object to determine the status of playing the video. Receipt of this event also indicates that the width and height properties of the video have been initialized or changed. 
Listen for the VideoEvent.RENDER_STATE event on the Video object. This event provides the same statuses as StageVideoEvent.RENDER_STATE, so you can also use it to determine whether GPU acceleration is available. Receipt of this event also indicates that the width and height properties of the video have been initialized or changed. (Not supported for AIR 2.5 for TV.)
*/

class Main extends Sprite
{
   static var sMain:Main;
   public static inline var PROGRESS_SIZE = 30;

   static inline var BACK = 0;
   static inline var PLAY = 1;
   static inline var PAUSE = 2;
   static inline var STOP = 3;
   static inline var NEXT = 4;

   var buttonData:BitmapData;
   var button:Sprite;
   var buttonAction:Int;
   var playing:Bool;
   var metaData:Dynamic;
   var duration:Float;
   var stream:NetStream;
   var progress:Sprite;
   var volumeControl:Sprite;
   var videoWidth:Float;
   var videoHeight:Float;
   var volume:Float;

   public function new()
   {
      super();
 
      playing = true;
      metaData = null;
      duration = 0;
      volume = 0.5;
      videoWidth = videoHeight = 0;
      buttonData = nme.Assets.getBitmapData("buttons");
      button = new Sprite();
      button.addEventListener(MouseEvent.CLICK, onClick );
      setButton(PAUSE);
      addChild(button);
      progress = new Sprite();
      addChild(progress);
      progress.addEventListener(MouseEvent.MOUSE_DOWN, beginSeek);
      addEventListener(nme.events.Event.ENTER_FRAME, function(_) { updateProgress(); } );

      volumeControl = new Sprite();
      addChild(volumeControl);
      volumeControl.addEventListener(MouseEvent.MOUSE_DOWN, beginVolume);
      volumeControl.x = 10;
      volumeControl.y = Std.int( (stage.stageHeight-100) * 0.5 );
      updateVolume();


      // In flash, we must wait for StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY
      if (stage.stageVideos.length<1)
      {
         trace("No video available");
      }
      else
      {
          trace("Loading...");
          var video = stage.stageVideos[0];

          var nc = new NetConnection(); 
          nc.connect(null);
          nc.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler); 

          stream = new NetStream(nc);
          var client:Dynamic = {};
          client.onMetaData = function(data:Dynamic)
          {
             metaData = data;
             duration  = metaData.duration;
             trace("metaData " + data.width + "," + data.height + "  for " + duration);
             videoWidth = data.width;
             videoHeight = data.height;
             centreVideo();
          };
          client.onPlayStatus = function(item:Dynamic)
          {
             trace("onPlayStatus " + item);
          };
          stream.client = client;

          stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
 
          //video.viewPort = new nme.geom.Rectangle(0,0,500,500);
          video.addEventListener(StageVideoEvent.RENDER_STATE, onRenderState);
          video.attachNetStream(stream);
          stream.play("http://download.wavetlan.com/SVV/Media/HTTP/H264/Talkinghead_Media/H264_test1_Talkinghead_mp4_480x360.mp4");

          // Seems flash needs this?
          addEventListener(nme.events.Event.ENTER_FRAME, function(_) { stream.bytesLoaded; } );
          stage.addEventListener(nme.events.Event.RESIZE, onResize );
      }
   }

   function centreVideo()
   {
      var video = stage.stageVideos[0];
      if (videoWidth<1 || videoHeight<1 || video==null)
         return;

      // Center video instance on Stage.
      var sx = stage.stageWidth / videoWidth;
      var sy = stage.stageHeight / videoHeight;
      var scale = sx<sy ? sx:sy;

      video.viewPort = new nme.geom.Rectangle(
                (stage.stageWidth - videoWidth*scale) / 2,
                (stage.stageHeight - videoHeight*scale) / 2,
                videoWidth*scale,
                videoHeight*scale );
   }



   function updateProgress()
   {
      var w = stage.stageWidth;
      progress.y = stage.stageHeight - PROGRESS_SIZE;
      var gfx = progress.graphics;
      gfx.clear();
      if (duration>0)
      {
         var t = stream.time;
         var total = stream.bytesTotal;
         var loaded = stream.bytesLoaded;


         gfx.lineStyle(1,0xffffff);
         gfx.beginFill(0x808080,0.5);
         gfx.drawRect(0.5,0.5,w-1,PROGRESS_SIZE-1);
         gfx.lineStyle();

         if (total>0)
         {
            gfx.beginFill(0x5050ff);
            gfx.drawRect(2,2,(w-4)*loaded/total,PROGRESS_SIZE-4);
         }
         gfx.beginFill(0x8080ff);
         gfx.drawRect(2,2,(w-4)*t/duration,PROGRESS_SIZE-4);
      }
      else
      {
         gfx.beginFill(0x808080,0.5);
         gfx.drawRect(0.5,0.5,w-1,PROGRESS_SIZE-1);
      }
   }

   function onSeek(evt:MouseEvent)
   {
      var fraction = evt.stageX / stage.stageWidth;
      stream.seek(fraction*duration);
   }

   function endSeek(_)
   {
      stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSeek);
      stage.removeEventListener(MouseEvent.MOUSE_UP, endSeek);
   }

   function beginSeek(_)
   {
      stage.addEventListener(MouseEvent.MOUSE_MOVE, onSeek);
      stage.addEventListener(MouseEvent.MOUSE_UP, endSeek);
   }

   function onClick(_)
   {
      playing = !playing;
      if (playing)
      {
         setButton(PAUSE);
         stream.resume();
      }
      else
      {
         setButton(PLAY);
         stream.pause();
      }
   }

   function updateVolume()
   {
      var gfx = volumeControl.graphics;
      gfx.clear();
      gfx.lineStyle(1,0xffffff);
      gfx.beginFill(0x00ff00,0.3);
      gfx.drawRect(0.5,0.5,20,100);
      
      gfx.lineStyle();
      gfx.beginFill(0x00ff00);
      gfx.drawRect(1.5,(1-volume)*100,18,volume*100);
   
   }

   function onVolume(evt:MouseEvent)
   {
      var pos = volumeControl.globalToLocal( new nme.geom.Point(evt.stageX,evt.stageY) );
      volume = 1.0-pos.y*0.01;
      if (volume<0)
         volume = 0.0;
      if (volume>1)
         volume = 1.0;
      updateVolume();

      stream.soundTransform = new SoundTransform(volume);
   }

   function endVolume(_)
   {
      stage.removeEventListener(MouseEvent.MOUSE_MOVE, onVolume);
      stage.removeEventListener(MouseEvent.MOUSE_UP, endVolume);
   }

   function beginVolume(_)
   {
      stage.addEventListener(MouseEvent.MOUSE_MOVE, onVolume);
      stage.addEventListener(MouseEvent.MOUSE_UP, endVolume);
   }

   function setButton(inMode:Int)
   {
      buttonAction = inMode;

      var gfx = button.graphics;
      gfx.clear();
      var mtx = new Matrix();
      mtx.translate( -inMode*60, 0 );
      gfx.beginBitmapFill( buttonData, mtx );
      gfx.drawRect(0,0,60,52);
      button.x = (stage.stageWidth-60)* 0.5;
      button.y = (stage.stageHeight-52)* 0.5;
   }

   function asyncErrorHandler(event:AsyncErrorEvent):Void 
   { 
      trace("asyncErrorHandler " + event);
   } 
   
   function netStatusHandler(event:NetStatusEvent):Void
   {
      trace("Net status " + event.info );
      switch (event.info.code)
      {
         case "NetConnection.Connect.Success":
            trace("You've connected successfully");
             
         case "NetStream.Publish.BadName":
            trace("Please check the name of the publishing stream" );
      }
   }

   function onResize(_)
   {
      setButton(buttonAction);
      updateVolume();
      updateProgress();
      centreVideo();
   }

   function onRenderState(ev:StageVideoEvent)
   {
      trace(ev.status);
   }
}


