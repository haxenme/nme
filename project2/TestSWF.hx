class TestSWF
{

static function CreateOne()
{
   var obj = new flash.display.Shape();
   var gfx = obj.graphics;


   var fillType = flash.display.GradientType.LINEAR;
   var colors =[0xFF0000, 0x0000FF];
   var alphas= [1, 1];
   var ratios= [0x00, 0xFF];
   var matr= new flash.geom.Matrix();
   matr.createGradientBox(100,100);
   var spreadMethod = flash.display.SpreadMethod.PAD;
   gfx.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
   gfx.drawRect(0,0,100,100);


   var colors =[0xFF0000, 0x0000FF];
   gfx.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
   gfx.drawRect(6,6,88,88);

   return obj;
}


static function CreateTwo()
{
   var obj = new flash.display.Shape();
   var gfx = obj.graphics;


   var fillType = flash.display.GradientType.LINEAR;
   var colors =[0xFF0000, 0x0000FF];
   var alphas= [1, 1];
   var ratios= [0x00, 0xFF];
   var matr= new flash.geom.Matrix();
   matr.createGradientBox(100,100);
   var spreadMethod = flash.display.SpreadMethod.PAD;
   gfx.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
   gfx.drawCircle(50,50,50);

   var colors =[0xFF0000, 0x0000FF];
   gfx.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
   gfx.drawCircle(50,50,44);

   return obj;
}





static function TestBlend(inStage:flash.display.DisplayObjectContainer)
{
   var modes = [
   flash.display.BlendMode.NORMAL,
   flash.display.BlendMode.LAYER,
   flash.display.BlendMode.MULTIPLY,
   flash.display.BlendMode.SCREEN,
   flash.display.BlendMode.LIGHTEN,
   flash.display.BlendMode.DARKEN,
   flash.display.BlendMode.DIFFERENCE,
   flash.display.BlendMode.ADD,
   flash.display.BlendMode.SUBTRACT,
   flash.display.BlendMode.INVERT,
   flash.display.BlendMode.ALPHA,
   flash.display.BlendMode.ERASE,
   flash.display.BlendMode.OVERLAY,
   flash.display.BlendMode.HARDLIGHT,
   ];

   for(i in 0...modes.length)
   {
      var container = new flash.display.Sprite();
      inStage.addChild(container);
      var x = i & 3;
      var y = i>>2;
      container.x = (x*150);
      container.y = (y*150);
      var obj1 =  CreateOne();
      container.addChild(obj1);
      var obj2 =  CreateTwo();
      obj2.x = (50);
      obj2.y = (50);
      obj2.blendMode = modes[i];
      container.addChild(obj2);
   }
}


public static function main()
{
   flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
   TestBlend(flash.Lib.current);
}

}
