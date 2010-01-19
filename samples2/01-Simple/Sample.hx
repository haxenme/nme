import nme2.Manager;

class Sample
{

public static function main()
{
   Manager.init(320,480, Manager.HARDWARE | Manager.RESIZABLE);

	var gfx = Manager.stage.graphics;
	gfx.beginFill(0xff0000);
	gfx.moveTo(100,100);
	gfx.lineTo(200,100);
	gfx.lineTo(200,200);
	gfx.lineTo(100,200);
	gfx.lineTo(100,100);
   Manager.mainLoop();
}

}
