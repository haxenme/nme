import nme.Lib;

class Sample
{

public static function main()
{
   var gfx = Lib.current.graphics;
   gfx.beginFill(0x000000);
   gfx.drawRect(120,0,120,320);

   for(side in 0...2)
   {
      var col = (0xFF + side * 0xFF ) % 0xffffff;

      // Plain text field
      var text = new nme.text.TextField();
      text.x = 10 + side*120;
      text.y = 10;
      text.textColor = col;
      text.width = 100;
      text.wordWrap = true;

      text.text = "Hello !\nFrom this multi-line, wordwrapped, centred text box!";
      
      var fmt = new nme.text.TextFormat();
      fmt.align = nme.text.TextFormatAlign.CENTER;
      text.setTextFormat(fmt);

      fmt = new nme.text.TextFormat();
      fmt.color = 0x660000;
      text.setTextFormat(fmt, 6, 12);

      fmt.color = 0xFF00FF;
      text.setTextFormat(fmt, 18);

      Lib.current.addChild(text);
      text.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;

      // HTML text fields
      var text = new nme.text.TextField();
      text.x = 10 + side*120;
      text.y = 120;
      text.textColor = col;
      text.htmlText = "<font size='16'>Hello !</font>";
      Lib.current.addChild(text);
 

      var text = new nme.text.TextField();
      text.x = 10 + side*120;
      text.y = 170;
      text.textColor = col;
      text.htmlText = "<font size='24'>Hello !</font>";
      Lib.current.addChild(text);


      var text = new nme.text.TextField();
      text.x = 10 + side*120;
      text.y = 220;
      text.textColor = col;
      text.htmlText = "<font size='36'>Hello !</font>";
      Lib.current.addChild(text);
   }
}

}
