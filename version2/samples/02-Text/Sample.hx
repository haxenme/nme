import nme.Lib;

class Sample
{

public static function main()
{
   Lib.init(320,480, Lib.HARDWARE | Lib.RESIZABLE);

   var text = new nme.text.TextField();
   text.x = 100;
   text.y = 100;
   text.text = "Hello !";
   Lib.stage.addChild(text);
   Lib.mainLoop();
}

}
