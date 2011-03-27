import flash.Lib;

class Sample
{

public static function main()
{
   var text = new flash.text.TextField();
   text.x = 10;
   text.y = 10;
   text.text = "Hello !";
   Lib.current.stage.addChild(text);
   text.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;

   var text = new flash.text.TextField();
   text.x = 10;
   text.y = 30;
   text.htmlText = "<font size='16'>Hello !</font>";
   Lib.current.stage.addChild(text);
 
   var text = new flash.text.TextField();
   text.x = 10;
   text.y = 50;
   text.htmlText = "<font size='24'>Hello !</font>";
   Lib.current.stage.addChild(text);

   var text = new flash.text.TextField();
   text.x = 10;
   text.y = 80;
   text.htmlText = "<font size='36'>Hello !</font>";
   Lib.current.stage.addChild(text);
}

}
