import nme.Lib;
import nme.media.Sound;

class Sample extends nme.display.Sprite
{

public function new()
{
   super();
   Lib.current.addChild(this);
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
