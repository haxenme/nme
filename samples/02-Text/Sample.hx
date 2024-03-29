import nme.display.*;
import nme.text.*;

class Sample extends Sprite
{
   public function new()
   {
      super();

      var gfx = graphics;
      gfx.beginFill(0x000000);
      gfx.drawRect(120,0,120,320);

      stage.scaleMode = StageScaleMode.NO_SCALE;
      //var uiScale = nme.ui.Scale.getFontScale();
      //scaleX = scaleY = uiScale;

      TextField.defaultAntiAliasType = stage.hasHardwareLcdFonts ?
                AntiAliasType.ADVANCED_LCD : AntiAliasType.ADVANCED;
      TextField.defaultForceFreeType = true;

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

         addChild(text);

         // HTML text fields
         var text = new nme.text.TextField();
         text.x = 10 + side*120;
         text.y = 120;
         text.textColor = col;
         text.htmlText = "<font size='16'>Hello !</font>";
         addChild(text);

         var text = new nme.text.TextField();
         text.x = 10 + side*120;
         text.y = 170;
         text.textColor = col;
         text.htmlText = "<font size='24'>Hello !</font>";
         addChild(text);


         var text = new nme.text.TextField();
         text.x = 10 + side*120;
         text.y = 220;
         text.textColor = col;
         text.htmlText = "<font size='36'>Hello !</font>";
         addChild(text);
      }

      var input = new nme.text.TextField();
      input.x = 20 + 2*120;
      input.y = 10;
      input.type = nme.text.TextFieldType.INPUT;
      input.wordWrap = true;
      input.multiline = true;
      input.width = 240;
      input.height = 300;
      input.text = "Input\n" + 
        "This app tests font rendering.  The LCD (Sub pixel) rendering on hardware requires " +
        "an extension that libAngle does not support on windows.\n" +
        "You can rebuild with \"neko build.n ndll-windows-m64 -DNME_NO_ANGLE\" or add " + 
        "the flag to your static links to increase the chances of finding hardware support.";
      input.border = true;
      input.borderColor = 0x000000;
      input.background = true;
      input.backgroundColor = 0xf0f0ff;
      addChild(input);

      var aaText = ["normal","advanced","advanced_lcd"];
      var cabText = ["software","hardware"];

      var tf = new nme.text.TextField();
      tf.autoSize = TextFieldAutoSize.LEFT;
      tf.y = 330;
      tf.x = 20;
      tf.htmlText = "<b>stage.hasHardwareLcdFonts " + stage.hasHardwareLcdFonts+ "</b>";
      tf.antiAliasType = AntiAliasType.ADVANCED_LCD;
      addChild(tf);

      for(side in 0...3)
         for(cab in 0...2)
            for(aa in 0...3)
            {
               var tf = new nme.text.TextField();
               tf.autoSize = TextFieldAutoSize.LEFT;
               tf.background = true;
               tf.backgroundColor = side!=1 ? 0xe0e0e0 : 0x202020;
               tf.border = true;
               tf.borderColor = side!=1 ? 0x000000 : 0x0000ff;
               tf.antiAliasType = aa;
               tf.textColor = side!=1 ? 0x000000 : 0xffffff;
               tf.forceFreeType = side==2;
               var freeT = side==2 ? "FreeType " : "";
               tf.text = "Utf1 Lorem Ipsum " + freeT + cabText[cab] + " " + aaText[aa];
               tf.cacheAsBitmap = cab==0;

               addChild(tf);
               tf.x = 20 + side*230;
               tf.y = 360 + aa*24 + cab*24*3;
            }
   }

}
