import nme.display.Sprite;
import nme.text.TextField;

class Main extends Sprite
{
   public function new()
   {
      super();
      var gfx = graphics;
      /*
      gfx.lineStyle(1,0x000000);
      gfx.moveTo(0,10.5);
      gfx.lineTo(200,10.5);
      gfx.moveTo(10.5,0);
      gfx.lineTo(10.5,200);
      */
      //gfx.drawRect(10,10,200,200);

      var tf = new TextField();
      tf.multiline = false;
      tf.border = true;
      tf.borderColor = 0x000000;
      tf.width = 600;
      tf.height = 50;
      tf.text = "Heuuuuualjsdhflkajsdhflasdhlfkas!";
      
      tf.x = 0;
      tf.y = 10;
      tf.scaleX = 1;
      tf.scaleY = 1;
      tf.autoSize = nme.text.TextFieldAutoSize.CENTER;

      //tf.type = nme.text.TextFieldType.INPUT;

      var ox = 5*2;
      var oy = 5*2;
      gfx.lineStyle(1,0xffff00);
      gfx.moveTo(0,oy+10.5);
      gfx.lineTo(200,oy+10.5);
      gfx.moveTo(ox+10.5,0);
      gfx.lineTo(ox+10.5,200);

      var w  = tf.textWidth * 5 + ox;
      var h  = tf.textHeight * 5 + oy;
      gfx.lineStyle(1,0x00ff00);
      gfx.moveTo(0,h+10.5);
      gfx.lineTo(200,h+10.5);
      gfx.moveTo(w+10.5,0);
      gfx.lineTo(w+10.5,200);

      var w  = tf.width;
      var h  = tf.height;
      gfx.lineStyle(1,0xff0000);
      gfx.moveTo(0,h+10.5);
      gfx.lineTo(600,h+10.5);
      gfx.moveTo(w+10.5,0);
      gfx.lineTo(w+10.5,600);

      //tf.cacheAsBitmap = true;
      addChild(tf);
      //tf.htmlText = "HELLO!\n<font color='#0000ff'>Blue There\nlakjdhf</font>akhfqklwhflqkjehflqjehlkq";
   }
}
