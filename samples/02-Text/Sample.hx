import flash.Lib;

class Sample
{

public static function main()
{
   var gfx = Lib.current.graphics;
   gfx.beginFill(0x000000);
   gfx.drawRect(120,0,120,120);

   for(side in 0...2)
   {
      var col = side * 0xffffff;
      var text = new flash.text.TextField();
      text.x = 10 + side*120;
      text.y = 10;
      text.textColor = col;
      text.text = "Hello !";
      Lib.current.addChild(text);
      text.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;

      var text = new flash.text.TextField();
      text.x = 10 + side*120;
      text.y = 30;
      text.textColor = col;
      text.htmlText = "<font size='16'>Hello !</font>";
      Lib.current.addChild(text);
 
      var text = new flash.text.TextField();
      text.x = 10 + side*120;
      text.y = 50;
      text.textColor = col;
      text.htmlText = "<font size='24'>Hello !</font>";
      Lib.current.addChild(text);

      var text = new flash.text.TextField();
      text.x = 10 + side*120;
      text.y = 80;
      text.textColor = col;
      text.htmlText = "<font size='36'>Hello !</font>";
      Lib.current.addChild(text);
   }
}

}
