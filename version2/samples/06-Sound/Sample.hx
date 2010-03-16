import nme.Lib;
import nme.media.Sound;

class Sample extends nme.display.Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);
	stage.addEventListener( nme.events.MouseEvent.CLICK,function(_) {
	   trace("Click");
	var sound = new Sound( new nme.net.URLRequest(neko.Sys.args()[0]) );
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
