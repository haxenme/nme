import nme.text.*;

class TestBase extends nme.display.Sprite
{
   public function resize() { }

   public function label(text:String, x:Float, y:Float)
   {
      var tf = new TextField();
      tf.textColor = 0xffffffff;
      tf.text = text;
      tf.autoSize = TextFieldAutoSize.LEFT;
      tf.x = x;
      tf.y = y;
      tf.scaleX = tf.scaleY = 1.0/scaleX;
      tf.selectable = false;
      addChild(tf);
   }

}
