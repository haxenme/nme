#if nme
import nme.Lib;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.events.MouseEvent;
import nme.events.Event;
#else
import flash.Lib;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.media.Sound;
import flash.net.URLRequest;
import flash.events.MouseEvent;
import flash.events.Event;
#end


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
         mImage = ApplicationMain.getAsset("Data/bang.png");
         mOffX = -Math.round(mImage.width/2);
         mOffY = -Math.round(mImage.height/2);

         // Can only play 1 mp3 at a time...
         mSound1 = ApplicationMain.getAsset("Data/drum.ogg");
         if (mSound1==null)
            trace("WARNING: Data/drumm.ogg failed to load");
         mSound2 = ApplicationMain.getAsset("Data/drums.ogg");
         if (mSound2==null)
            trace("WARNING: Data/drums.ogg failed to load");
         mSound3 = ApplicationMain.getAsset("Data/bass.wav");
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
   public function new()
   {
      super();

      Lib.current.stage.addChild(this);

      var bmp = new Bitmap();
      bmp.bitmapData = ApplicationMain.getAsset("Data/drum_kit.jpg");
      addChild(bmp);


      var sound_name = "Data/Party_Gu-Jeremy_S-8250_hifi.mp3";
      var sound:Sound = ApplicationMain.getAsset(sound_name);
      if (sound==null)
      {
         trace("WARNING: " + sound_name + " failed to load");
      }
      else
      {
         var channel = sound.play(0,-1);
         channel.addEventListener( Event.SOUND_COMPLETE, function(_) { trace("Complete"); } );
      }

      stage.addEventListener( MouseEvent.MOUSE_DOWN, onClick );
   }

   public function onClick(inEvent:MouseEvent)
   {
      addChild( new Bang( inEvent.stageX, inEvent.stageY ) );
   }

   public static function main()
   {
      new Sample();
   }

}
