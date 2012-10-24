package pack.flash.components.scroller.view;

#if js
//typedef UInt = Int
#end

import pack.cross.components.scroller.model.ScrollModel;
import pack.cross.components.scroller.events.ScrollEvent;
import pack.cross.data.Rectangle;

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.geom.Rectangle;
import flash.events.MouseEvent;
import flash.events.Event;

class Scroller extends Sprite {

	public var model( default, setModel ) : ScrollModel;
	
	var dirty : Bool;
	var mouseDown : Bool;
	var upCallback : Void -> Void;
	
	var background : Sprite;
	var thumb : Sprite;
	
	var clickMousePosition : {x : Float, y : Float};
	var clickThumbPosition : {x : Float, y : Float};
	
	public function new( w : Float, h : Float, ?upCallback : Void -> Void, ?model : ScrollModel ) {
		super();
		
		dirty = true;
		mouseDown = false;
		
		this.upCallback = upCallback;
		if( model != null ) {
			this.model = model;
			this.model.addEventListener( ScrollEvent.UPDATE, changed );
			//this.model.changedSignaler.bind(changed);
		} else
			createModel(w, h);
		
		createElements(w, h);
		draw();
		
		addEventListener( Event.ADDED_TO_STAGE, addListeners );
	}
	
	function setModel( m : ScrollModel ) {
		
		if (model != null) {
			model.removeEventListener( ScrollEvent.UPDATE, changed );
			//model.changedSignaler.unbind(changed);
			model = null;
		}
		model = m;
		model.addEventListener( ScrollEvent.UPDATE, changed );
		//model.changedSignaler.bind(changed);
		dirty = true;
		return m;
		return null;
	}
	
	function createModel( w : Float, h : Float ) {
		setModel( new ScrollModel(new Rectangle(0,0,w,h), new Rectangle(20,0,w/2,h)) );
	}
	
	function createElements( w : Float, h : Float ) {
		
		addChild(background = new Sprite());
		addChild(thumb = new Sprite());
		
		drawRect(background, w, h, 0xff0000);
		drawRect(thumb, w, h, 0x0000ff);
	}
	
	public function addListeners(_) {
		
		removeEventListener( Event.ADDED_TO_STAGE, addListeners );
		
		flash.Lib.trace(thumb);
		thumb.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		//thumb.addEventListener( MouseEvent.CLICK, onMouseDown );
	}
	
	public function drawRect( d : Sprite, w : Float, h : Float, col : Int, ?alpha : Float = 1.0 ) : Sprite {
		var gfx = d.graphics;
		gfx.beginFill( col, alpha );
		gfx.drawRect( 0, 0, w, h );
		gfx.endFill();
		return d;
	}
	
	//public function changed( data : TScroll ) : Void {
	public function changed( _ ) : Void {
		dirty = true;
	}
	
	function draw() {
		
		var data = model.data;
		
		background.width = data.total.width;
		background.height = data.total.height;
		background.x = data.total.x;
		
		thumb.width = data.thumb.width;
		thumb.height = data.thumb.height;
		thumb.x = data.thumb.x;
		
		dirty = false;
	}
	
	function handleNewFrame(_) {
		if(dirty ) draw();
	}
	
	function onMouseDown( e : MouseEvent ) {
		flash.Lib.trace("onmousedown : " + this);
		
		mouseDown = true;
		stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
		stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		stage.addEventListener( Event.ENTER_FRAME, handleNewFrame );
		
		clickMousePosition = { x : e.stageX, y : e.stageY };
		clickThumbPosition = { x : model.data.thumb.x, y : model.data.thumb.y };
		draw();
	}
	
	function onMouseUp( e : MouseEvent ) {
		
		stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );
		stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		stage.removeEventListener( Event.ENTER_FRAME, handleNewFrame );
		
		mouseDown = false;
		model.setThumbPosition( clickThumbPosition.x + (e.stageX - clickMousePosition.x) );
		draw();
		
		if( upCallback != null )
			upCallback();
	}
	
	function onMouseMove( e : MouseEvent ) {
		model.setThumbPosition( clickThumbPosition.x + (e.stageX - clickMousePosition.x) );
	}
	
	public function destroy() : Void {
		
		model.removeEventListener( ScrollEvent.UPDATE, changed );
		//model.changedSignaler.unbind(changed);
		removeEventListener( Event.ADDED_TO_STAGE, addListeners );
		thumb.removeEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		if( mouseDown ) {
			stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			stage.removeEventListener( Event.ENTER_FRAME, handleNewFrame );
		}
	}
	
}
