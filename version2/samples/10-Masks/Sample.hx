#if !flash
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.display.BitmapData;
import nme.display.Graphics;
import nme.Lib;
import nme.display.Shape;
import nme.text.TextField;
import nme.geom.Matrix;
import nme.events.MouseEvent;
#else
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.Lib;
import flash.display.Shape;
import flash.text.TextField;
import flash.geom.Matrix;
import flash.events.MouseEvent;
#end



class Sample extends Sprite 
{
   var mask_obj:Sprite;

   public function new()
   {
      super();
      Lib.current.addChild(this);


      var bg = new Sprite();
      var gfx = bg.graphics;
      gfx.beginFill(0x808080);
      gfx.drawRect(0,0,640,480);
      addChild(bg);


      var tf:TextField = new TextField();
      tf.text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " 
                  + "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ";
      tf.selectable = false;
      tf.wordWrap = true;
      tf.width = 150;
      tf.name = "text1";
      addChild(tf);
      
      mask_obj = new Sprite();
      mask_obj.graphics.beginFill(0xFF0000);
      mask_obj.graphics.drawCircle(0,0,40);
      mask_obj.graphics.endFill();
      mask_obj.name = "mask_obj";
      addChild(mask_obj);


      var mask_child = new Shape();
      var gfx = mask_child.graphics;
      gfx.beginFill(0x00ff00);
      gfx.drawRect(-60,-10,120,20);
      mask_obj.addChild(mask_child);

      mask = mask_obj;

      tf.addEventListener(MouseEvent.MOUSE_DOWN, drag);
      stage.addEventListener(MouseEvent.MOUSE_UP, noDrag);
      tf.x = 100;
      tf.y = 100;
      mask_obj.x = 100;
      mask_obj.y = 100;
   }

	function drag(event:MouseEvent):Void{
       mask_obj.startDrag();
   }
   function noDrag(event:MouseEvent):Void {
       mask_obj.stopDrag();
   }

	public static function main()
	{
	#if !flash
		nme.Lib.create(function(){new Sample();},550,400,60,0xffeeee,
			  (0*nme.Lib.HARDWARE) | nme.Lib.RESIZABLE);
	#else
		new Sample();
	#end
	}


}

