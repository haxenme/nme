package browser.geom;


import browser.geom.Point;


class Matrix {
	
	
	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx (default, set_tx):Float;
	public var ty (default, set_ty):Float;
	
	public var _sx:Float;
	public var _sy:Float;
	
	
	public function new (in_a:Float = 1, in_b:Float = 0, in_c:Float = 0, in_d:Float = 1, in_tx:Float = 0, in_ty:Float = 0) {
		
		a = in_a;
		b = in_b;
		c = in_c;
		d = in_d;
		tx = in_tx;
		ty = in_ty;
		_sx = 1.0;
		_sy = 1.0;
		
	}
	
	
	private inline function cleanValues ():Void {
		
		a = Math.round (a * 1000) / 1000;
		b = Math.round (b * 1000) / 1000;
		c = Math.round (c * 1000) / 1000;
		d = Math.round (d * 1000) / 1000;
		tx = Math.round (tx * 10) / 10;
		ty = Math.round (ty * 10) / 10;
		
	}
	
	
	public inline function clone ():Matrix {
		
		var m = new Matrix (a, b, c, d, tx, ty);
		m._sx = _sx;
		m._sy = _sy;
		return m;
		
	}
	
	
	public function concat (m:Matrix):Void {
		
		var a1 = a * m.a + b * m.c;
		b = a * m.b + b * m.d;
		a = a1;

		var c1 = c * m.a + d * m.c;
		d = c * m.b + d * m.d;
		c = c1;
		
		var tx1 = tx * m.a + ty * m.c + m.tx;
		ty = tx * m.b + ty * m.d + m.ty;
		tx = tx1;
		
		_sx *= m._sx;
		_sy *= m._sy;
		
		cleanValues ();
		
	}
	
	
	public function copy (m:Matrix):Void {
		
		a = m.a;
		b = m.b;
		c = m.c;
		d = m.d;
		tx = m.tx;
		ty = m.ty;
		_sx = m._sx;
		_sy = m._sy;
		
	}
	
	
	public function createGradientBox (in_width:Float, in_height:Float, rotation:Float = 0, in_tx:Float = 0, in_ty:Float = 0):Void {
		
		a = in_width / 1638.4;
		d = in_height / 1638.4;
		
		// rotation is clockwise
		if (rotation != null && rotation != 0.0) {
			
			var cos = Math.cos (rotation);
			var sin = Math.sin (rotation);
			
			b = sin * d;
			c = -sin * a;
			a *= cos;
			d *= cos;
			
		} else {
			
			b = 0;
			c = 0;
			
		}
		
		tx = (in_tx != null ? in_tx + in_width / 2 : in_width / 2);
		ty = (in_ty != null ? in_ty + in_height / 2 : in_height / 2);
		
	}
	
	
	public function identity ():Void {
		
		a = 1;
		b = 0;
		c = 0;
		d = 1;
		tx = 0;
		ty = 0;
		_sx = 1.0;
		_sy = 1.0;
		
	}
	
	
	public function invert ():Matrix {
		
		var norm = a * d - b * c;
		
		if (norm == 0) {
			
			a = b = c = d = 0;
			tx = -tx;
			ty = -ty;
			
		} else {
			
			norm = 1.0 / norm;
			var a1 = d * norm;
			d = a * norm;
			a = a1;
			b *= -norm;
			c *= -norm;
			
			var tx1 = - a * tx - c * ty;
			ty = - b * tx - d * ty;
			tx = tx1;
			
		}
		
		_sx /= _sx;
		_sy /= _sy;
		
		cleanValues ();
		return this;
		
	}
	
	
	public inline function mult (m:Matrix) {
		
		var result = clone ();
		result.concat (m);
		return result;
		
	}
	
	
	public inline function nmeTransformX (inPos:Point):Float {
		
		return inPos.x * a + inPos.y * c + tx;
		
	}
	
	
	public inline function nmeTransformY (inPos:Point):Float {
		
		return inPos.x * b + inPos.y * d + ty;
		
	}
	
	
	public inline function nmeTranslateTransformed (inPos:Point):Void {
		
		tx = nmeTransformX (inPos);
		ty = nmeTransformY (inPos);
		
		cleanValues ();
		
	}
	
	
	public function rotate (inTheta:Float):Void {
		
		/*
		   Rotate object "after" other transforms
			
		   [  a  b   0 ][  ma mb  0 ]
		   [  c  d   0 ][  mc md  0 ]
		   [  tx ty  1 ][  mtx mty 1 ]
			
		   ma = md = cos
		   mb = -sin
		   mc = sin
		   mtx = my = 0
			
		 */
		
		var cos = Math.cos (inTheta);
		var sin = Math.sin (inTheta);
		
		var a1 = a * cos - b * sin;
		b = a * sin + b * cos;
		a = a1;
		
		var c1 = c * cos - d * sin;
		d = c * sin + d * cos;
		c = c1;
		
		var tx1 = tx * cos - ty * sin;
		ty = tx * sin + ty * cos;
		tx = tx1;
		
		cleanValues ();
		
	}
	
	
	public function scale (inSX:Float, inSY:Float) {
		
		/*
			
		   Scale object "after" other transforms
			
		   [  a  b   0 ][  sx  0   0 ]
		   [  c  d   0 ][  0   sy  0 ]
		   [  tx ty  1 ][  0   0   1 ]
		 */
		
		_sx = inSX;
		_sy = inSY;
		a *= inSX;
		b *= inSY;
		c *= inSX;
		d *= inSY;
		tx *= inSX;
		ty *= inSY;
		
		cleanValues ();
		
	}
	
	
	private inline function setRotation (inTheta:Float, inScale:Float = 1) {
		
		var scale:Float = inScale;
		
		a = Math.cos (inTheta) * scale;
		c = Math.sin (inTheta) * scale;
		b = -c;
		d = a;
		
		cleanValues ();
		
	}
	
	
	public inline function to3DString ():String {
		
		// identityMatrix
		//  [a,b,tx,0],
		//  [c,d,ty,0],
		//  [0,0,1, 0],
		//  [0,0,0, 1]
		//
		// matrix3d(a,       b, 0, 0, c, d,       0, 0, 0, 0, 1, 0, tx,     ty, 0, 1)
		
		return "matrix3d(" + a + ", " + b + ", " + "0, 0, " + c + ", " + d + ", " + "0, 0, 0, 0, 1, 0, " + tx + ", " + ty + ", " + "0, 1" + ")";
		
	}
	
	
	public inline function toMozString () {
		
		return "matrix(" + a + ", " + b + ", " + c + ", " + d + ", " + tx + "px, " + ty + "px)";
		
	}
	
	
	public inline function toString ():String {
		
		return "matrix(" + a + ", " + b + ", " + c + ", " + d + ", " + tx + ", " + ty + ")";
		
	}
	
	
	public function transformPoint (inPos:Point) {
		
		return new Point (nmeTransformX (inPos), nmeTransformY (inPos));
		
	}
	
	
	public function translate (inDX:Float, inDY:Float) {
		
		var m = new Matrix ();
		m.tx = inDX;
		m.ty = inDY;
		this.concat (m);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_tx (inValue:Float):Float {
		
		tx = inValue;// * _sx;
		return tx;
		
	}
	
	
	private function set_ty (inValue:Float):Float {
		
		ty = inValue;// * _sy;
		return ty;
		
	}
	
	
}