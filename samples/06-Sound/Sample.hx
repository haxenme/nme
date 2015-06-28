import nme.Lib;
import nme.geom.Point;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.events.MouseEvent;
import nme.events.Event;
import nme.Assets;

import nme.events.SampleDataEvent;

class Bang extends Bitmap
{
   static var mImage : BitmapData = null;
   static var mSound1 : Sound = null;
   static var mSound2 : Sound = null;
   static var mSound3 : Sound = null;
   static var mOffX = 0;
   static var mOffY = 0;


   public function new(inX:Float, inY:Float)
   {
      super();

      if (mImage==null)
      {
         mImage = Assets.getBitmapData("Data/bang.png");
         mOffX = -Math.round(mImage.width/2);
         mOffY = -Math.round(mImage.height/2);

         // Can only play 1 mp3 at a time...
         mSound1 = Assets.getSound("Data/drum.ogg");
         if (mSound1==null)
            trace("WARNING: Data/drumm.ogg failed to load");
         mSound2 = Assets.getSound("Data/drums.ogg");
         if (mSound2==null)
            trace("WARNING: Data/drums.ogg failed to load");
         mSound3 = Assets.getSound("Data/bass.wav");
         if (mSound3==null)
            trace("WARNING: Data/bass.wav failed to load");
      }

      bitmapData = mImage;
      x = inX + mOffX;
      y = inY + mOffY;

      if (inY<100 && mSound2!=null)
         mSound2.play(0,0);
      else if (inY>200 && mSound3!=null)
         mSound3.play(0,0);
      else if (mSound1!=null)
         mSound1.play(0,0);

      var me = this;
      haxe.Timer.delay( function() me.Remove(), 200 );
   }

   function Remove()
   {
      parent.removeChild(this);
   }


}



class Sample extends Sprite
{
   var mDown:Bool;
   var mWasDown:Bool;
   var mPhase0:Float;
   var mFrequency:Float;
   var mLeftVolume:Float;
   var mRightVolume:Float;
   var mPrevLeftVolume:Float;
   var mPrevRightVolume:Float;
   var mBuzzStart:Sprite;
   var mBuzz:Sound;
   static var canPlayMid = true;
   static var canPlayFile = true;

   public function new()
   {
      super();

      mDown = false;
      mWasDown = false;
      Lib.current.stage.addChild(this);

      var bmp = new Bitmap();
      bmp.bitmapData = Assets.getBitmapData("Data/drum_kit.jpg");
      addChild(bmp);

      mPrevLeftVolume = mLeftVolume = 1.0;
      mPrevRightVolume = mRightVolume = 1.0;
      mFrequency = 0.05;

      playMusic("rock");

      mBuzzStart = new Sprite();
      var gfx = mBuzzStart.graphics;
      gfx.beginFill(0xff0000);
      gfx.lineStyle(2,0x000000);
      gfx.drawCircle(0,0,10);
      addChild(mBuzzStart);
      mBuzzStart.cacheAsBitmap = true;
      var text = new nme.text.TextField();
      text.text = "Drag Me!";
      text.mouseEnabled = false;
      text.autoSize = nme.text.TextFieldAutoSize.LEFT;
      text.x = 10;
      text.y = -5;
      mBuzzStart.addChild(text);
      mBuzzStart.x = 200;
      mBuzzStart.y = 10;
      mPhase0 = 0;

      mBuzz = new Sound();
      mBuzz.addEventListener( SampleDataEvent.SAMPLE_DATA, onFillData );

      stage.addEventListener( MouseEvent.MOUSE_UP, onUp );
      stage.addEventListener( MouseEvent.MOUSE_DOWN, onClick );
      stage.addEventListener( MouseEvent.MOUSE_MOVE, onMove );
      //stage.addEventListener( Event.ENTER_FRAME, doDelay );
      stage.addEventListener( Event.RESIZE, setScale );
      setScale(null);
   }

   function setScale(_)
   {
      var sW = 400;
      var sH = 300;
      var w = stage.stageWidth;
      var h = stage.stageHeight;

      if (w*sH < h*sW)
      {
         scaleX = scaleY = w/sW;
         x = 0;
         y = (h-scaleY*sH) * 0.5;
      }
      else
      {
         scaleX = scaleY = h/sH;
         x = (w-scaleX*sW) * 0.5;
         y = 0;
      }
   }

   //function doDelay(_) { Sys.sleep(1.0); }

   function playMusic(inId:String)
   {
      if (inId=="rock" && !canPlayFile)
         return;
      if (inId=="classical" && !canPlayMid)
         return;
      var sound:Sound = Assets.getMusic(inId);
      if (sound==null)
      {
         trace("WARNING: " + inId + " could not load asset");
      }
      else
      {
         var channel = sound.play(0,1);
         if (channel==null)
         {
            trace("Could not play '" + inId + "' on this system.");
            if (inId=="rock")
               canPlayFile = false;
            else if (inId=="classical")
               canPlayMid = false;

             var next = inId=="rock" ? "classical" : "rock";
             playMusic(next);
         }
         else
         {
           channel.addEventListener( Event.SOUND_COMPLETE, function(_)
            {
               var next = inId=="rock" && canPlayMid ? "classical" :
                           canPlayFile ? "rock" :
                           "";
               if (next!="")
               {
                  trace("Complete - play " + next);
                  playMusic(next);
               }
            } );
         }
      }
   }


   public function onFillData(dataEvent:SampleDataEvent)
   {
      var size = 2048;
      var freq = mFrequency;
      var data = dataEvent.data;

      if (!mDown)
         size  = 100;
      
      // Ease in to avoid pops....
      var first = mDown!=mWasDown ? 100 : 0;

      if (mDown)
      {
         for(i in 0...first)
         {
            var value = Math.sin(mPhase0 + i*freq) * i / 100;
            data.writeFloat(value*(mLeftVolume*i + mPrevLeftVolume*(100-i) ) / 100);
            data.writeFloat(value*(mRightVolume*i + mPrevRightVolume*(100-i) ) / 100);
         }
         for(i in first...size)
         {
            var value = Math.sin(mPhase0 + i*freq);
            data.writeFloat(value*mLeftVolume);
            data.writeFloat(value*mRightVolume);
         }
      }
      else
      {
         for(i in 0...first)
         {
            var value = Math.sin(mPhase0 + i*freq) * (100-i) / 100;
            data.writeFloat(value*(mLeftVolume*i + mPrevLeftVolume*(100-i) ) / 100);
            data.writeFloat(value*(mRightVolume*i + mPrevRightVolume*(100-i) ) / 100);
         }
         for(i in first...size)
         {
            data.writeFloat( 0.0 );
            data.writeFloat( 0.0 );
         }
      }

      mWasDown = mDown;
      if (!mDown && !mWasDown)
         mPhase0 = 0;
      else
         mPhase0 = (mPhase0 + size*freq) % (Math.PI*2.0);
      mPrevLeftVolume = mLeftVolume;
      mPrevRightVolume = mRightVolume;
   }

   public function onMove(inEvent:MouseEvent)
   {
      var right = 2*inEvent.stageX / stage.stageWidth;
      mRightVolume = right > 1 ? 1 : right;
      var left = 2 - right;
      mLeftVolume = left > 1 ? 1 : left;

      mFrequency = 0.5 * inEvent.stageY / stage.stageHeight;
   }

   public function onClick(inEvent:MouseEvent)
   {
      if (inEvent.target == mBuzzStart)
      {
         mDown = true;
         var channel = mBuzz.play();
         channel.addEventListener( Event.SOUND_COMPLETE, function(_) { trace("Complete"); } );
      }
      else
      {
         var pos = globalToLocal( new Point(inEvent.stageX, inEvent.stageY ) );
         addChild( new Bang(pos.x,pos.y) );
      }
   }

   public function onUp(inEvent:MouseEvent)
   {
      mDown = false;
   }
}



