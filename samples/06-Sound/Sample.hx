import nme.Lib;
import nme.media.Sound;

class Sample extends nme.display.Sprite
{

public function new()
{
#if (iphoneos || iphonesim)
   var sound_name = "Party_Gu-Jeremy_S-8250_hifi.mp3";
#else
   var sound_name = neko.Sys.args()[0];
#end

   super();
   Lib.current.addChild(this);
	stage.addEventListener( nme.events.MouseEvent.MOUSE_DOWN,function(_) {
	   trace("Click");
	var sound = new Sound( new nme.net.URLRequest(sound_name) );
		var channel = sound.play(0,1);
		channel.addEventListener( nme.events.Event.SOUND_COMPLETE, function(_) {
		    trace("Complete"); } );
		});
}


public static function main()
{
#if flash
   new Sample();
#else
   Lib.create(function(){new Sample();},320,480,60,0xccccff,(1*Lib.HARDWARE) | Lib.RESIZABLE);
#end
}

}
