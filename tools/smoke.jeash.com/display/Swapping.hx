package ;

import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

class Swapping {

	static function main() {
		new Swapping();
	}

	public function new() {
		var s:Sprite=addEvents(50,0x000000);
		s=addEvents(70,0xff0000);
		s=addEvents(90,0x0000ff);
	}

	private function addEvents(num:Int,clr:Int):Sprite {
		var s:Sprite = new Sprite();
		s.name = num+" ";
		s.graphics.beginFill(clr);
		s.graphics.drawCircle(25, 25, 25);
		var shape:Shape = new Shape();
		shape.graphics.beginFill(0xff00ff);
		shape.graphics.drawRect(10, 10, 10, 10);
		s.addChild(shape);
		flash.Lib.current.addChild(s);
		s.addEventListener(MouseEvent.MOUSE_DOWN, swapMe);
		s.x = num;
		s.y = num;
		return s;
	}

	private function swapMe(e:Event) {

		if (Std.is(e.target,Sprite)){
			var s:Sprite = e.target;
			flash.Lib.trace(s.name);
			var p:MovieClip = cast(s.parent, MovieClip);
			s.parent.setChildIndex(s, s.parent.numChildren - 1); 
		}else {
			trace(Type.typeof(e.target));
		}
	}
}


