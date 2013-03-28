package furusystems.display.gl.camera;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.gl.GLUtils;
import nme.Lib;
import nme.utils.ByteArray;
import nme.Vector;
class Camera {
	
	public var width:Float = 1;
	public var height:Float = 1;
	public var fieldOfView:Float;
	public var near:Float = 0.01;
	//public var near:Float = 1;
	public var far:Float = 5000;
	
	public var defaultMoveAmount:Float = 1;
	public var defaultRotationAmount:Float;
	
	public var p:Vector3D;
	
	public var yaw:Float = 0;
	public var pitch:Float = 0;
	public var roll:Float = 0;
	
	public var view:Matrix3D;
	public var projection:Matrix3D;
	public var camProj:Matrix3D;
	
	public var rotation:Matrix3D;
	
	private var forward:Vector3D;
	
	public function new(p:Vector3D = null, yaw:Float = 0, pitch:Float = 0, roll:Float = 0) {
		defaultRotationAmount = Math.PI / 20;
		view = new Matrix3D();
		projection = new Matrix3D();
		camProj = new Matrix3D();
		rotation = new Matrix3D();
		forward = new Vector3D();
		this.p = new Vector3D();
		
		reset();
		if (p!=null) {
			this.p = p;
		} else {
			p = this.p;
		}
		this.yaw = yaw;
		this.pitch = pitch;
		this.roll = roll;
		update();
	}
	
	public function reset():Void {
		p.x = p.y = p.z = p.w = 0;
		yaw = pitch = roll = 0;
		fieldOfView = 70;
	}
	
	private function updateProjection():Void {
		projection = GLUtils.projectionPerspective(fieldOfView, width / height, near, far);
	}
	
	
	private function updateRotationalMatrix():Void {
		rotation.identity();
		rotation.appendRotation(-roll, Vector3D.Z_AXIS);
		rotation.appendRotation(-pitch, Vector3D.X_AXIS);
		rotation.appendRotation(-yaw, Vector3D.Y_AXIS);
		//rotation.appendRotation(yaw, Vector3D.Y_AXIS);
		//rotation.appendRotation(pitch, Vector3D.X_AXIS);
		//rotation.appendRotation(roll, Vector3D.Z_AXIS);
	}
	
	public var o(get_o, set_o):Vector3D;
	private function get_o():Vector3D {
		return view.position;
	}
	private function set_o(v:Vector3D):Vector3D{
		view.position = v;
		return view.position;
	}
	
	public var d(get_d, null):Vector3D;
	private function get_d():Vector3D {
		return view.deltaTransformVector(new Vector3D());
	}
	
	public var x(get_x, set_x):Float;
	private function get_x():Float {
		return p.x;
	}
	private function set_x(v:Float):Float {
		p.x = v;
		return p.x;
	}
	
	public var y(get_y, set_y):Float;
	private function get_y():Float {
		return p.y;
	}
	private function set_y(v:Float):Float {
		p.y = v;
		return p.y;
	}
	
	public var z(get_z, set_z):Float;
	private function get_z():Float {
		return p.z;
	}
	private function set_z(v:Float):Float {
		p.z = v;
		return p.z;
	}
	
	public function moveForward(amount:Float):Void {
		move(0, 0, -amount);
	}
	public function moveBackward(amount:Float):Void {
		move(0, 0, amount);
	}
	public function moveLeft(amount:Float):Void {
		move(-amount, 0, 0);
	}
	public function moveRight(amount:Float):Void {
		move(amount, 0, 0);
	}
	public function moveUp(amount:Float):Void {
		move(0, amount, 0);
	}
	public function moveDown(amount:Float):Void {
		move(0, -amount, 0);
	}
	public function move(x:Float, y:Float, z:Float):Void {
		var v:Vector3D = new Vector3D(x, y, z);
		p.incrementBy(rotation.transformVector(v));
		updateMatrix();
	}
	
	public function rotateLeft(?amount:Float):Void {
		if (amount == null) amount = defaultRotationAmount;
		rotate(0, -amount, 0);
	}
	public function rotateRight(?amount:Float):Void {
		if (amount==null) amount = defaultRotationAmount;
		rotate(0, amount, 0);
	}
	public function rotateUp(?amount:Float):Void {
		if (amount==null) amount = defaultRotationAmount;
		rotate(-amount, 0, 0);
	}
	public function rotateDown(?amount:Float):Void {
		if (amount==null) amount = defaultRotationAmount;
		rotate(amount, 0, 0);
	}
	public function rotateCW(?amount:Float):Void {
		if (amount==null) amount = defaultRotationAmount;
		rotate(0, 0, -amount);
	}
	public function rotateCCW(?amount:Float):Void {
		if (amount==null) amount = defaultRotationAmount;
		rotate(0, 0, amount);
	}
	
	public function rotate(yawDelta:Float = 0, pitchDelta:Float = 0, rollDelta:Float = 0, lockPitch:Bool = true):Void {
		yaw += yawDelta;
		pitch += pitchDelta;
		pitch = Math.max(-90, Math.min(90, pitch));
		roll += rollDelta;
		updateRotationalMatrix();
		
		/*
		var mv:Vector.<Vector3D> = matrix.decompose(Orientation3D.EULER_ANGLES);
		var mr:Vector3D = mv[1];
		mr.x = yaw;
		mr.y = pitch;
		mr.z = roll;
		matrix.recompose(mv, Orientation3D.EULER_ANGLES);*/
	}
	
	public function lookAt(target:Vector3D, ?up:Vector3D):Void {
		if (up==null) up = Vector3D.Y_AXIS;
		
		forward.setTo(target.x-p.x, target.y-p.y, target.z-p.z);
		forward.normalize();
		
		var ex:Float = p.x;
		var ey:Float = p.y;
		var ez:Float = p.z;
		var fx:Float = forward.x;
		var fy:Float = forward.y;
		var fz:Float = forward.z;
		var ux:Float = up.x;
		var uy:Float = up.y;
		var uz:Float = up.z;
		var sx:Float = fy*uz - fz*uy;
		var sy:Float = fz*ux - fx*uz;
		var sz:Float = fx*uy - fy*ux;
		
		ux = sy*fz - sz*fy;
		uy = sz*fx - sx*fz;
		uz = sx*fy - sy*fx;
		
		fx = -fx; fy = -fy;	fz = -fz;
		
		var data:Vector<Float> = view.rawData;
		data[0] = sx;
		data[1] = ux;
		data[2] = fx;
		data[3] = 0;
		data[4] = sy;
		data[5] = uy;
		data[6] = fy;
		data[7] = 0;
		data[8] = sz;
		data[9] = uz;
		data[10] = fz;
		data[11] = 0;
		data[12] = -(sx*ex+sy*ey+sz*ez);
		data[13] = -(ux*ex+uy*ey+uz*ez);
		data[14] = -(fx*ex+fy*ey+fz*ez);
		data[15] = 1;
		view.rawData = data;
		
		updateCamProj();
	}
	
	public function update(custom:Bool = false):Void {
		updateProjection();
		updateRotationalMatrix();
		if (!custom) updateMatrix();
		updateCamProj();
	}
	
	private function updateMatrix():Void {
		view.identity();
		//matrix.appendTranslation(p.x, p.y, p.z);
		view.appendTranslation(-p.x, -p.y, -p.z);
		view.appendRotation(yaw, Vector3D.Y_AXIS);
		view.appendRotation(pitch, Vector3D.X_AXIS);
		view.appendRotation(roll, Vector3D.Z_AXIS);
	}
	
	private function updateCamProj():Void {
		camProj.identity();
		camProj.append(view);
		camProj.append(projection);
	}
	
	public function export(bytes:ByteArray):Void {
		var data:Vector<Float> = view.rawData;
		for (i in 0...data.length) {
			bytes.writeDouble(data[i]);
		}
	}
	public function load(bytes:ByteArray):Void {
		var data:Vector<Float> = view.rawData;
		for (i in 0...data.length) {
			data[i] = bytes.readDouble();
		}
		view.rawData = data;
	}
	
	public function toString():String {
		return p.x+" "+p.y+" "+p.z+"), "+yaw+" "+pitch+" "+roll;
	}
	
	public function clone():Camera {
		var c:Camera = new Camera();
		c.view = view.clone();
		c.p = p.clone();
		c.yaw = yaw;
		c.pitch = pitch;
		c.roll = roll;
		c.width = width;
		c.height = height;
		c.fieldOfView = fieldOfView;
		c.near = near;
		c.far = far;
		c.defaultMoveAmount = defaultMoveAmount;
		c.defaultRotationAmount = defaultRotationAmount;
		return c;
	}
}