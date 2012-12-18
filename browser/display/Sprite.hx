package browser.display;


import browser.display.Graphics;
import browser.display.InteractiveObject;
import browser.events.MouseEvent;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.Lib;


class Sprite extends DisplayObjectContainer {
	
	
	public var buttonMode:Bool;
	public var dropTarget (get_dropTarget, never):DisplayObject;
	public var graphics (get_graphics, never):Graphics;
	public var useHandCursor (default, set_useHandCursor):Bool;
	
	private var nmeCursorCallbackOut:Dynamic->Void;
	private var nmeCursorCallbackOver:Dynamic->Void;
	private var nmeDropTarget:DisplayObject;
	private var nmeGraphics:Graphics;
	
	
	public function new () {
		
		super ();
		
		nmeGraphics = new Graphics ();
		buttonMode = false;
		
	}
	
	
	public override function nmeGetGraphics ():Graphics {
		
		return nmeGraphics;
		
	}
	
	
	public function startDrag (lockCenter:Bool = false, bounds:Rectangle = null):Void {
		
		if (nmeIsOnStage ()) {
			
			stage.nmeStartDrag (this, lockCenter, bounds);
			
		}
		
	}
	
	
	public function stopDrag ():Void {
		
		if (nmeIsOnStage ()) {
			
			stage.nmeStopDrag (this);
			var l = parent.nmeChildren.length - 1;
			var obj:DisplayObject = stage;
			
			for (i in 0...parent.nmeChildren.length) {
				
				var result = parent.nmeChildren[l - i].nmeGetObjectUnderPoint (new Point (stage.mouseX, stage.mouseY));
				if (result != null) obj = result;
				
			}
			
			if (obj != this) {
				
				nmeDropTarget = obj;
				
			} else {
				
				nmeDropTarget = stage;
				
			}
			
		}
		
	}
	
	
	override public function toString ():String {
		
		return "[Sprite name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_dropTarget ():DisplayObject {
		
		return nmeDropTarget;
		
	}
	
	
	private function get_graphics ():Graphics {
		
		return nmeGraphics;
		
	}
	
	
	private function set_useHandCursor (cursor:Bool):Bool {
		
		if (cursor == this.useHandCursor) return cursor;
		
		if (nmeCursorCallbackOver != null) {
			
			removeEventListener (MouseEvent.ROLL_OVER, nmeCursorCallbackOver);
			
		}
		
		if (nmeCursorCallbackOut != null) {
			
			removeEventListener (MouseEvent.ROLL_OUT, nmeCursorCallbackOut);
			
		}
		
		if (!cursor) {
			
			Lib.nmeSetCursor (Default);
			
		} else {
			
			nmeCursorCallbackOver = function (_) { Lib.nmeSetCursor (Pointer); }
			nmeCursorCallbackOut = function (_) { Lib.nmeSetCursor (Default); }
			addEventListener (MouseEvent.ROLL_OVER, nmeCursorCallbackOver);
			addEventListener (MouseEvent.ROLL_OUT, nmeCursorCallbackOut);
			
		}
		
		this.useHandCursor = cursor;
		return cursor;
		
	}
	
	
}