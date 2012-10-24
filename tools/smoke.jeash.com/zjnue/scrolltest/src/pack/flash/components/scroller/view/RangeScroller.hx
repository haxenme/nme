package pack.flash.components.scroller.view;

import pack.cross.components.scroller.model.ScrollModel;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.Event;

class RangeScroller extends Scroller {
	
	var tabLeft : Sprite;
	var tabRight : Sprite;
	
	var clickedTab : Sprite;
	var clickThumbSize : {x : Float, y : Float};
	
	public function new( w : Float, h : Float, ?upCallback : Void -> Void, ?model : ScrollModel ) {
		super(w, h, upCallback, model);
	}
	
	override function createElements( w : Float, h : Float ) {
		super.createElements(w,h);
		
		addChild(tabLeft = new Sprite());
		addChild(tabRight = new Sprite());
		
		drawRect(tabLeft, 5, h, 0x00ff00);
		drawRect(tabRight, 5, h, 0x00ff00);
	}
	
	override public function addListeners(_) {
		super.addListeners(_);
		tabLeft.addEventListener( MouseEvent.MOUSE_DOWN, onTabMouseDown );
		tabRight.addEventListener( MouseEvent.MOUSE_DOWN, onTabMouseDown );
	}
	
	override function draw() {
		super.draw();
		var data = model.data;
		tabLeft.x = data.thumb.x - tabLeft.width / 2;
		tabRight.x = data.thumb.x + data.thumb.width - tabRight.width / 2;
	}
	
	function onTabMouseDown( e : MouseEvent ) {
		flash.Lib.trace("onTabMouseDown : " + this);
		
		mouseDown = true;
		stage.addEventListener( MouseEvent.MOUSE_UP, onTabMouseUp );
		stage.addEventListener( MouseEvent.MOUSE_MOVE, onTabMouseMove );
		stage.addEventListener( Event.ENTER_FRAME, handleNewFrame );
		
		clickMousePosition = { x : e.stageX, y : e.stageY };
		clickThumbPosition = { x : model.data.thumb.x, y : model.data.thumb.y };
		clickThumbSize = { x : model.data.thumb.width, y : model.data.thumb.height };
		clickedTab = e.target;
		draw();
	}
	
	function onTabMouseUp( e : MouseEvent ) {
		
		stage.removeEventListener( MouseEvent.MOUSE_UP, onTabMouseUp );
		stage.removeEventListener( MouseEvent.MOUSE_MOVE, onTabMouseMove );
		stage.removeEventListener( Event.ENTER_FRAME, handleNewFrame );
		
		mouseDown = false;
		update(e);
		draw();
		
		if( upCallback != null )
			upCallback();
	}
	
	function onTabMouseMove( e : MouseEvent ) {
		update(e);
	}
	
	function update( e : MouseEvent ) {
		var delta = e.stageX - clickMousePosition.x;
		
		if( clickedTab == tabLeft )
			model.sizeThumbLeft(clickThumbPosition.x + delta);
		else
			model.setThumbWidth( clickThumbSize.x + delta );
	}
	
	override public function destroy() : Void {
		super.destroy();
		
		tabLeft.removeEventListener( MouseEvent.MOUSE_DOWN, onTabMouseDown );
		tabRight.removeEventListener( MouseEvent.MOUSE_DOWN, onTabMouseDown );
	}
	
}
