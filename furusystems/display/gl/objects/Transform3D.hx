package furusystems.display.gl.objects;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;

/**
 * ...
 * @author Andreas Rønning
 */
class Transform3D
{
	public var children:List<Transform3D>;
	public var parent:Transform3D = null;
	
	public var position:Vector3D;
	public var rotation:Vector3D;
	public var scale:Vector3D;
	public var pivot:Vector3D;
	
	private var _matrix:Matrix3D;
	
	private var _dirty:Bool = true;
	
	public function new() 
	{
		pivot = null;
		position = new Vector3D();
		rotation = new Vector3D();
		scale = new Vector3D(1, 1, 1, 1);
		children = new List<Transform3D>();
		_matrix = new Matrix3D();
	}
	
	//position
	public var x(get_x, set_x):Float;
	private function set_x(nx:Float):Float {
		position.x = nx;
		_dirty = true;
		return position.x;
	}
	private function get_x():Float {
		return position.x;
	}
	
	public var y(get_y, set_y):Float;
	private function set_y(ny:Float):Float {
		position.y = ny;
		_dirty = true;
		return position.y;
	}
	private function get_y():Float {
		return position.y;
	}
	
	public var z(get_z, set_z):Float;
	private function set_z(nz:Float):Float {
		position.z = nz;
		_dirty = true;
		return position.z;
	}
	private function get_z():Float {
		return position.z;
	}
	
	//rotation
	public var rx(get_rx, set_rx):Float;
	private function set_rx(nrx:Float):Float {
		rotation.x = nrx;
		_dirty = true;
		return rotation.x;
	}
	private function get_rx():Float {
		return rotation.x;
	}
	
	public var ry(get_ry, set_ry):Float;
	private function set_ry(nry:Float):Float {
		rotation.y = nry;
		_dirty = true;
		return rotation.y;
	}
	private function get_ry():Float {
		return rotation.y;
	}
	
	public var rz(get_rz, set_rz):Float;
	private function set_rz(nrz:Float):Float {
		rotation.z = nrz;
		_dirty = true;
		return rotation.z;
	}
	private function get_rz():Float {
		return rotation.z;
	}
	
	//scale
	public var sx(get_sx, set_sx):Float;
	private function set_sx(nsx:Float):Float {
		scale.x = nsx;
		_dirty = true;
		return scale.x;
	}
	private function get_sx():Float {
		return scale.x;
	}
	
	public var sy(get_sy, set_sy):Float;
	private function set_sy(nsy:Float):Float {
		scale.y = nsy;
		_dirty = true;
		return scale.y;
	}
	private function get_sy():Float {
		return scale.y;
	}
	
	public var sz(get_sz, set_sz):Float;
	
	private function set_sz(nsz:Float):Float {
		scale.z = nsz;
		_dirty = true;
		return scale.z;
	}
	private function get_sz():Float {
		return scale.z;
	}
	
	
	public var matrix(get_matrix, null):Matrix3D;
	private function get_matrix():Matrix3D {
		if (_dirty) {
			updateMatrix();
		}
		return _matrix;
	}
	
	public function getGlobal():Matrix3D {
		var root:Transform3D = getRoot();
		return root.matrix;
	}
	
	public function getRoot():Transform3D {
		if (parent == null) return this;
		return parent.getRoot();
	}
	
	public function addChild(t:Transform3D):Transform3D {
		if (t.parent != null) {
			t.parent.removeChild(t);
		}
		t.parent = this;
		children.add(t);
		return t;
	}
	
	public function removeChild(t:Transform3D):Transform3D {
		if (children.remove(t)) {
			t.parent = null;
		}
		return t;
	}
	
	public function predraw(parent:Matrix3D = null):Void {
		var m = matrix;
		if (parent != null) {
			m.append(parent);
			_dirty = true;
		}
		for (c in children) {
			c.predraw(m);
		}
	}
	
	public function prerender():Void {
		
	}
	
	public function update():Void {
		for (c in children) {
			c.update();
		}
	}
	
	private function updateMatrix():Void 
	{
		if (!_dirty) return;
		_matrix.identity();
		_matrix.appendRotation(rotation.x, Vector3D.X_AXIS, pivot);
		_matrix.appendRotation(rotation.y, Vector3D.Y_AXIS, pivot);
		_matrix.appendRotation(rotation.z, Vector3D.Z_AXIS, pivot);
		_matrix.appendScale(scale.x, scale.y, scale.z);
		_matrix.appendTranslation(position.x, position.y, position.z);
		_dirty = false;
	}
	
}