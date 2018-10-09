import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.geom.ColorTransform;

class ColourTransform extends TestBase
{
   var bmp:BitmapData;
   var tx:Int = 0;
   var ty:Int = 0;

   public function new()
   {
      super();
      scaleX = scaleY = 4;

      // Colour transform only applies to non-zero alpha?
      bmp = new BitmapData(16,16,true,0x01000000);
      var shape = new Sprite();
      var gfx = shape.graphics;
      gfx.beginFill(0xffffff);
      gfx.drawCircle(8,8,8);
      bmp.draw(shape);

      addTest("Normal", null);
      addTest("Inv-alpha", new ColorTransform(0,0,0,-1,0,0,0,255) );
      addTest("HalfGreen", new ColorTransform(1,0.5,1,1,0,0,0,0) );
   }

   function addTest(name:String, transform:ColorTransform)
   {
      //var data2 = new BitmapData(100,100,true, 0x00);
      //data2.draw( new Bitmap(data), null, new ColorTransform(0,0,0,-1,0,0,0,255) );

      var bitmap = new Bitmap(bmp);
      if (transform!=null)
         bitmap.transform.colorTransform = transform;
      addChild(bitmap);
      bitmap.x = tx;
      bitmap.y = ty;
      label(name,tx,ty+20);
      tx += 20;
      if (tx>700)
      {
         tx = 0;
         ty += 30;
      }
   }
   override public function resize()
   {
      var gfx = graphics;
      gfx.clear();
      gfx.beginFill(0x808080);
      gfx.drawRect(0,0,stage.stageWidth/4+1, stage.stageHeight/4+1);
   }

}


