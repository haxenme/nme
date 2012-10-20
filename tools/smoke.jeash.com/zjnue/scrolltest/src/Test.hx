package;

import pack.flash.components.scroller.view.Scroller;
import pack.flash.components.scroller.view.RangeScroller;
import pack.flash.components.scroller.view.MyRangeScroller;

#if !(flash || jeash)
import nme.display.Sprite;
import nme.Lib;
#else
import flash.display.Sprite;
import flash.Lib;
#end

class Test extends Sprite {
	
	var s : Scroller;
	var rs : RangeScroller;
	var mrs : MyRangeScroller;
	
	public static function main() {
		#if !(flash || jeash)
		      nme.Lib.create(function(){new Test();},550,400,60,0xffeeee,
		           (0*nme.Lib.HARDWARE) | nme.Lib.RESIZABLE);
		   #else
		      new Test();
   		#end
	}
	
	public function new() {
		super();
		
		Lib.current.addChild(this);
		
		addChild(s = new Scroller(200, 20));
		addChild(rs = new RangeScroller(200, 20));
		addChild(mrs = new MyRangeScroller(400, 40));
		
		s.x = 20;
		s.y = 50;
		rs.x = 20;
		rs.y = 100;
		mrs.x = 20;
		mrs.y = 150;
	}	
}
