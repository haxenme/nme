package browser.display;
#if js


import browser.display.DisplayObject;
import browser.display.InteractiveObject;
import browser.events.MouseEvent;
import browser.media.SoundTransform;


class SimpleButton extends DisplayObjectContainer {
	
	
	public var downState(default, set_downState):DisplayObject;
	public var enabled:Bool;
	public var hitTestState(default, set_hitTestState):DisplayObject;
	public var overState(default, set_overState):DisplayObject;
	public var soundTransform:SoundTransform;
	public var trackAsMenu:Bool;
	public var upState(default, set_upState):DisplayObject;
	public var useHandCursor:Bool;
	
	private var currentState(default, set_currentState):DisplayObject;
	
	
	public function new(upState:DisplayObject = null, overState:DisplayObject = null, downState:DisplayObject = null, hitTestState:DisplayObject = null) {
		
		super();
		
		this.upState = (upState != null) ? upState : nmeGenerateDefaultState();
		this.overState = (overState != null) ? overState : nmeGenerateDefaultState();
		this.downState = (downState != null) ? downState : nmeGenerateDefaultState();
		this.hitTestState = (hitTestState != null) ? hitTestState : nmeGenerateDefaultState();
		
		currentState = this.upState;
		
	}
	
	
	override private function nmeAddToStage(newParent:DisplayObjectContainer, beforeSibling:DisplayObject = null):Void {
		
		for (child in nmeChildren) {
			
			if (!child.nmeIsOnStage()) {
				
				child.nmeAddToStage(newParent);
				
			}
			
		}
		
	}
	
	
	private function nmeGenerateDefaultState():DisplayObject {
		
		return new DisplayObject();
		
	}
	
	
	private function switchState(state:DisplayObject):Void {
		
		if (this.currentState != null && this.currentState.nmeIsOnStage()) {
			
			// hack: addChild currently does not add to document with empty nmeGraphics
			state.nmeAddToStage(parent, this.currentState); 
			removeChild(this.currentState);
			addChild(state);
			
		} else {
			
			if (parent != null) state.nmeAddToStage(parent); 
			addChild(state);
			
		}
		
	}
	
	
	override public function toString():String {
		
		return "[SimpleButton name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_currentState(state:DisplayObject):DisplayObject {
		
		if (currentState == state) return state;
		switchState(state);
		
		return currentState = state;
		
	}
	
	
	private function set_downState(downState:DisplayObject):DisplayObject {
		
		if (this.downState != null && currentState == this.downState) currentState = downState;
		return this.downState = downState;
		
	}
	
	
	private function set_hitTestState(hitTestState:DisplayObject):DisplayObject {
		
		if (hitTestState != this.hitTestState) {
			
			// Events bubble up to this instance.
			addEventListener(MouseEvent.MOUSE_OVER, function(_) { if (overState != currentState) currentState = overState; });
			addEventListener(MouseEvent.MOUSE_OUT, function(_) {  if (upState != currentState) currentState = upState; });
			addEventListener(MouseEvent.MOUSE_DOWN, function(_) { currentState = downState; });
			addEventListener(MouseEvent.MOUSE_UP, function(_) { currentState = overState; });
			
			hitTestState.alpha = 0.0;
			addChild(hitTestState);
			
		}
		
		return this.hitTestState = hitTestState;
		
	}
	
	
	private function set_overState(overState:DisplayObject):DisplayObject {
		
		if (this.overState != null && currentState == this.overState) currentState = overState;
		return this.overState = overState;
		
	}
	
	
	private function set_upState(upState:DisplayObject):DisplayObject {
		
		if (this.upState != null && currentState == this.upState) currentState = upState;
		return this.upState = upState;
		
	}
	
	
}


#end