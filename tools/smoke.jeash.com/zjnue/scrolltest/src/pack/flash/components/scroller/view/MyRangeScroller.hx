package pack.flash.components.scroller.view;

import pack.cross.components.scroller.model.ScrollModel;

import flash.geom.Rectangle;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.Event;

class MyRangeScroller extends RangeScroller {
	
	var thumbPressMarker : Sprite;
	
	public function new( w : Float, h : Float, ?upCallback : Void -> Void, ?model : ScrollModel ) {
		super(w, h, upCallback, model);
	}
	
	override function createElements( w : Float, h : Float ) {
		
		addChild(background = new Sprite());
		addChild(thumb = new Sprite());
		
		drawRect(background, w, h, 0x000000, 0.05);
		drawRect(thumb, w, h, 0x000000, 0.2);
		
		addChild(tabLeft = new Sprite());
		addChild(tabRight = new Sprite());
		
		drawRect(tabLeft, 4, h, 0x000000);
		drawRect(tabRight, 4, h, 0x000000);
		
		addChild(thumbPressMarker = new Sprite());
	}
	
	override function draw() {
		super.draw();
		if (mouseDown)
			drawMarker();
		else
			thumbPressMarker.graphics.clear();
	}
	
	function drawMarker() {
		var gfx = thumbPressMarker.graphics;
		gfx.clear();
		gfx.lineStyle( 0.5, 0x000000, 1.0 );
		gfx.drawRect( 0.25, 0.25, tabRight.width + thumb.width - 0.5, tabRight.height - 0.5 );
		thumbPressMarker.x = tabLeft.x;
	}
	
}
