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
      input.text = "Input";
      input.border = true;
      input.borderColor = 0x000000;
      input.background = true;
      input.backgroundColor = 0xf0f0ff;
      addChild(input);

      var aaText = ["normal","advanced","advanced_lcd"];
      var cabText = ["software","hardware"];
      for(cab in 0...2)
         for(aa in 0...3)
         {
            var tf = new nme.text.TextField();
            tf.autoSize = TextFieldAutoSize.LEFT;
            tf.background = true;
            tf.backgroundColor = 0xe0e0e0;
            tf.border = true;
            tf.borderColor = 0x000000;
            tf.antiAliasType = aa;
            tf.text = "Utf1 Lorem Ipsum " +  cabText[cab] + " " + aaText[aa];
            tf.cacheAsBitmap = cab==1;

            addChild(tf);
            tf.x = 20;
            tf.y = 350 + aa*24 + cab*24*3;
         }
   }

}
