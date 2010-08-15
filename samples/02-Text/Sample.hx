import nme.Lib;

class Sample
{

public static function main()
{
   Lib.create(function() {
   var text = new nme.text.TextField();
   text.x = 100;
   text.y = 100;
   text.text = "Hello !";
   Lib.stage.addChild(text);

	}, 320,480, 100, 0xffffff, Lib.HARDWARE | Lib.RESIZABLE);
}

}
