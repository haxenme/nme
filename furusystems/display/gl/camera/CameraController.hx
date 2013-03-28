package furusystems.display.gl.camera;
import nme.display.InteractiveObject;
import nme.display.Stage;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.KeyboardEvent;
import nme.events.MouseEvent;
import nme.geom.Matrix3D;
import nme.geom.Point;
import nme.geom.Vector3D;
import nme.ui.Keyboard;
class CameraController extends EventDispatcher{
	public static inline var REALTIME:Int = 0;
	public static inline var STEP:Int = 1;
	public static inline var MAP:Int = 2;
	public static inline var GLOBE:Int = 3;
	
	public var type:Int = REALTIME;
	
	public var cam:Camera;
	
	private var target:InteractiveObject;
	private var stage:Stage;
	
	private var targetMatrix:Matrix3D;
	public var v:Vector3D;
	private var moveThreshold:Float = 1e-4;
	
	private var lookOffset:Point;
	private var camOffset:Vector3D;
	
	private var mouseDownOffset:Point;
	private var dragThreshold:Float = 2;
	
	private var orbitTarget:Vector3D = null;
	
	private var mouseView:Bool = false;
	private var forward:Bool = false;
	private var backward:Bool = false;
	private var left:Bool = false;
	private var right:Bool = false;
	private var up:Bool = false;
	private var down:Bool = false;
	private var slower:Bool = false;
	private var faster:Bool = false;
	private var moveSpeed:Float;
	private var staticRotationSpeed:Float;
	
	private var t:Float = 0;
	
	public var mapZoom:Int = 1;
	
	public function new(?cam:Camera) {
		super();
		staticRotationSpeed  = 0.005/Math.PI*180;
		lookOffset = new Point();
		mouseDownOffset = new Point();
		targetMatrix = new Matrix3D();
		v = new Vector3D();
		camOffset = new Vector3D();
		if (cam == null) cam = new Camera();
		this.cam = cam;
	}
	public function init(newTarget:InteractiveObject, newStage:Stage):Void {
		if (target!=null) {
			target.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			target.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
			target.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			target.removeEventListener(KeyboardEvent.KEY_UP, keyUp);
		}
		
		target = newTarget;
		stage = newStage;
		
		//target.focusRect = false;
		
		target.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		target.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
		target.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		target.addEventListener(KeyboardEvent.KEY_UP, keyUp);
	}
	
	public var moving(get_moving, null):Bool;
	private function get_moving():Bool {
		if (mouseView) return true;
		//if (v.length > moveThreshold) return true;
		//if (forward || backward || left || right || up || down) return true;
		if (v.length > moveThreshold || forward || backward || left || right || up || down) return true;
		return false;
	}
	
	private function keyDown(e:KeyboardEvent):Void {
		//var c:Camera = cam;
		//c.defaultMoveAmount = e.shiftKey ? 10 : (e.ctrlKey ? 0.1 : 1);
		switch (e.keyCode) {
			case 87: case Keyboard.UP: forward = true; 
			case 83: case Keyboard.DOWN: backward = true; 
			case 65: case Keyboard.LEFT: left = true; 
			case 68: case Keyboard.RIGHT: right = true; 
			case 69: up = true;  // E
			case 81:  down = true;  // Q
			case Keyboard.SHIFT: faster = true; 
			case Keyboard.CONTROL: slower = true; 
		}
	}
	private function keyUp(e:KeyboardEvent):Void {
		switch (e.keyCode) {
			case 87: case Keyboard.UP: forward = false; 
			case 83: case Keyboard.DOWN: backward = false; 
			case 65: case Keyboard.LEFT: left = false; 
			case 68: case Keyboard.RIGHT: right = false; 
			case 69: up = false;  // E
			case 81: down = false;  // Q
			case Keyboard.SHIFT: faster = false; 
			case Keyboard.CONTROL: slower = false; 
		}
	}
	
	private function mouseDown(e:MouseEvent):Void {
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		
		mouseDownOffset.x = lookOffset.x = target.mouseX;
		mouseDownOffset.y = lookOffset.y = target.mouseY;
		camOffset.x = cam.x;
		camOffset.y = cam.y;
		camOffset.z = cam.z;
		
		//mouseView = true;
	}
	
	private function mouseWheel(e:MouseEvent):Void {
		/*switch (type) {
			
			case MAP:
				var prevZoom:Int = mapZoom;
				if (e.delta > 0) {
					mapZoom *= 2;
				} else {
					mapZoom /= 2;
				}
				mapZoom = Math.max(1, Math.min(64, mapZoom));
				
				if (mapZoom != prevZoom) {
					var dx:Float = target.mouseX-cam.width/2;
					var dy:Float = target.mouseY-cam.height/2;
					var dmz:Float = mapZoom > prevZoom ? 1/mapZoom : -1/prevZoom;
					cam.x += dx*dmz;
					cam.z += dy*dmz;
					dispatchEvent(new Event(Event.CHANGE));
				}
				
			case GLOBE:
				v.z += e.delta*3e-3;
				
		}*/
	}
	
	private function mouseMove(e:MouseEvent):Void {
		var dx:Float = target.mouseX-mouseDownOffset.x;
		var dy:Float = target.mouseY-mouseDownOffset.y;
		
		if (dx*dx+dy*dy > dragThreshold*dragThreshold) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			mouseView = true;
		}
		
	}
	
	private function mouseUp(e:MouseEvent):Void {
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		
		var dx:Float = target.mouseX-mouseDownOffset.x;
		var dy:Float = target.mouseY-mouseDownOffset.y;
		if (dx*dx+dy*dy <= dragThreshold*dragThreshold) {
			dispatchEvent(new MouseEvent(MouseEvent.CLICK, false, false, target.mouseX, target.mouseY));
		}
		
		mouseView = false;
	}
	
	/*
	private function mouseMove(e:MouseEvent):Void {
		var dx:Float = target.mouseX-lookOffset.x;
		var dy:Float = target.mouseY-lookOffset.y;
		
		//targetMatrix.appendRotation(dx*0.2, Vector3D.Y_AXIS);
		//targetMatrix.appendRotation(dy*0.2, Vector3D.X_AXIS);
		lookOffset.x = target.mouseX; lookOffset.y = target.mouseY;
	}
	*/
	
	public function orbitTo(x:Float, y:Float):Void {
		orbitTarget = new Vector3D(x, y);
	}
	private function angleDifference(source:Float, target:Float):Float {
		var diff:Float = target - source;
		diff %= Math.PI*2;
		diff += (diff > Math.PI) ? -Math.PI*2 : ((diff < -Math.PI) ? Math.PI*2 : 0);
		return diff;
	}
	
	public function run():Void {
		
		var changed:Bool = false;
		var dx:Float;
		var dy:Float;
		
		if (mouseView) {
			switch (type) {
				
				case REALTIME:
					//dx = (target.mouseX-target.width/2)*360*0.0001*Math.sqrt(moveSpeed);
					//dy = (target.mouseY-target.height/2)*360*0.0001*Math.sqrt(moveSpeed);
					dx = (target.mouseX-stage.stageWidth/2)*360*0.00001;
					dy = (target.mouseY-stage.stageHeight/2)*360*0.00001;
					cam.rotate(dx, dy);
					
					changed = true;
					
				case STEP:
					if (target.mouseX != lookOffset.x || target.mouseY != lookOffset.y) {
						dx = target.mouseX-lookOffset.x;
						dy = target.mouseY-lookOffset.y;
						cam.rotate(dx*staticRotationSpeed, dy*staticRotationSpeed);
						
						lookOffset.x = target.mouseX;
						lookOffset.y = target.mouseY;
						
						changed = true;
					}
					
				case MAP:
					//dx = (target.mouseX-target.width/2)*0.01;
					//dy = (target.mouseY-target.height/2)*0.01;
					dx = target.mouseX-lookOffset.x;
					dy = target.mouseY-lookOffset.y;
					
					cam.x = camOffset.x-dx/mapZoom;
					cam.z = camOffset.z-dy/mapZoom;
					
					changed = true;
					
				case GLOBE:
					//var mult:Float = 360*3e-5/(Math.max(1, 2-0.1*Math.exp(-cam.p.z)));
					
					//var mult:Float = Math.PI*2*3e-5/(Math.max(1, 1+cam.p.z));
					var mult:Float = Math.PI*2*3e-5;
					dx = (target.mouseX-lookOffset.x)*mult;
					dy = (target.mouseY-lookOffset.y)*mult;
					
					lookOffset.x = target.mouseX;
					lookOffset.y = target.mouseY;
					
					v.x += dy;
					v.y += dx;
					
					changed = true;
			}
			
			
			//cam.rotate(dx);
		}
		
		switch (type) {
			
			case REALTIME:
				moveSpeed = 0.01;
				if (slower) moveSpeed *= 0.1;
				if (faster) moveSpeed *= 10;
				if (forward) v.z -= moveSpeed;
				if (backward) v.z += moveSpeed;
				if (left) v.x -= moveSpeed;
				if (right) v.x += moveSpeed;
				if (up) v.y += moveSpeed;
				if (down) v.y -= moveSpeed;
				v.x *= 0.9;
				v.y *= 0.9;
				v.z *= 0.9;
				if (v.length > moveThreshold) {
					cam.move(v.x, v.y, v.z);
					changed = true;
				} else {
					v.x = v.y = v.z = 0;
				}
				if (changed) cam.update();
				
			case STEP:
				if (forward || backward || left || right || up || down) {
					cam.defaultMoveAmount = 1;
					if (slower) cam.defaultMoveAmount *= 0.1;
					if (faster) cam.defaultMoveAmount *= 10;
					if (forward) cam.moveForward(cam.defaultMoveAmount);
					if (backward) cam.moveBackward(cam.defaultMoveAmount);
					if (left) cam.moveLeft(cam.defaultMoveAmount);
					if (right) cam.moveRight(cam.defaultMoveAmount);
					if (up) cam.moveUp(cam.defaultMoveAmount);
					if (down) cam.moveDown(cam.defaultMoveAmount);
					forward = backward = left = right = up = down = false;
					changed = true;
				}
				if (changed) cam.update();
				
			case GLOBE:
				
				moveSpeed = 0.1;
				if (left) v.y += moveSpeed;
				if (right) v.y -= moveSpeed;
				if (forward) v.x += moveSpeed;
				if (backward) v.x -= moveSpeed;
				if (up) v.z += moveSpeed*0.1;
				if (down) v.z -= moveSpeed*0.1;
				
				if (orbitTarget!=null) {
					dx = angleDifference(cam.p.x, orbitTarget.x);
					dy = angleDifference(cam.p.y, orbitTarget.y);
					//v.x += dx*0.05; v.y += dy*0.05;
					//v.x *= 0.8; v.y *= 0.8;
					v.x += dx*0.1; v.y += dy*0.1;
					v.x *= 0.6; v.y *= 0.6;
					if (dx*dx+dy*dy < 0.01 && v.length < 0.005) {
						orbitTarget = null;
					}
				}
				
				v.x *= 0.95;
				v.y *= 0.95;
				v.z *= 0.95;
				cam.p.x += v.x;
				cam.p.y += v.y;
				cam.p.z += v.z;
				
				cam.view.identity();
				cam.view.appendRotation(cam.p.y*180/Math.PI, Vector3D.Y_AXIS);
				cam.view.appendRotation(cam.p.x*180/Math.PI, Vector3D.X_AXIS);
				cam.view.appendTranslation(0, 0, -15+cam.p.z);
				cam.update(true);
				changed = true;
				
			default: if (changed) cam.update();
			
		}
		
		t++;
		
		if (changed) dispatchEvent(new Event(Event.CHANGE));
		
		//cam.matrix = targetMatrix.clone();
	}
	
	
}