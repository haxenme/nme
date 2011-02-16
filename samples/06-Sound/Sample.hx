import nme.Lib;
import nme.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;


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
         mImage = BitmapData.load("Data/bang.png");
         mOffX = -Math.round(mImage.width/2);
         mOffY = -Math.round(mImage.height/2);


         // Can only play 1 mp3 at a time...
         mSound1 = new Sound( new nme.net.URLRequest("Data/drum.ogg") );
         mSound2 = new Sound( new nme.net.URLRequest("Data/drums.ogg") );
         mSound3 = new Sound( new nme.net.URLRequest("Data/bass.wav") );
      }

      bitmapData = mImage;
      x = inX + mOffX;
      y = inY + mOffY;

      if (inY<100)
         mSound2.play(0,0);
      else if (inY>200)
         mSound3.play(0,0);
      else
         mSound1.play(0,0);
      var me = this;
      haxe.Timer.delay( function() me.Remove(), 200 );
   }

   function Remove()
   {
      parent.removeChild(this);
   }


}



class Sample extends nme.display.Sprite
{
   public function new()
   {
      super();

      nme.Lib.current.stage.addChild(this);

      var bmp = new Bitmap();
      bmp.bitmapData = BitmapData.load("Data/drum_kit.jpg");
      addChild(bmp);


      var sound_name = "Data/Party_Gu-Jeremy_S-8250_hifi.mp3";
      var sound = new Sound( new nme.net.URLRequest(sound_name), true );
      var channel = sound.play(0,-1);
      channel.addEventListener( nme.events.Event.SOUND_COMPLETE, function(_) { trace("Complete"); } );

      addEventListener( nme.events.MouseEvent.MOUSE_DOWN, onClick );
   }

   public function onClick(inEvent:nme.events.MouseEvent)
   {
      addChild( new Bang( inEvent.stageX, inEvent.stageY ) );
   }

   public static function main()
   {
      new Sample();
   }

}
