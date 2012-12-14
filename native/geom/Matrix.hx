package native.geom;


/*
  Contrary to any adobe documentation , points transform with:
  [ X'  Y'  ]   =  [ X  Y  1 ] [  a   b ]
                               [  c   d ]
                               [  tx  ty]
*/
class Matrix #if cpp implements cpp.rtti.FieldNumericIntegerLookup #end {	
	
	
	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx:Float;
	public var ty:Float;
	
	
	public function new (?in_a:Float, ?in_b:Float, ?in_c:Float, ?in_d:Float, ?in_tx:Float, ?in_ty:Float) {
		
		a = in_a == null ? 1.0 : in_a;
		b = in_b == null ? 0.0 : in_b;
		c = in_c == null ? 0.0 : in_c;
		d = in_d == null ? 1.0 : in_d;
		tx = in_tx == null ? 0.0 : in_tx;
		ty = in_ty == null ? 0.0 : in_ty;
		
	}
	
	
	public function clone ():Matrix {
		
		return new Matrix (a, b, c, d, tx, ty);
		
	}
	
	
	/*
		A "translate" . concat "rotate" rotates the translation component.
		ie,
		
		[X'] = [X][trans][rotate]
		
		
		Multiply "after" other transforms ...
		
		
		[  a  b   0 ][  ma mb  0 ]
		[  c  d   0 ][  mc md  0 ]
		[  tx ty  1 ][  mtx mty 1 ]
	*/
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
		
	}
	
	
	public function createBox (scaleX:Float, scaleY:Float, ?rotation:Float, ?tx:Float, ?ty:Float):Void {
		
		a = scaleX;
		d = scaleY;
		b = rotation == null ? 0.0 : rotation;
		this.tx = tx == null ? 0.0 : tx;
		this.ty = ty == null ? 0.0 : ty;
		
	}
	
	
	public function createGradientBox (in_width:Float, in_height:Float, ?rotation:Float, ?in_tx:Float, ?in_ty:Float):Void {
		
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
			
			b = c = 0;
			
		}
		
		tx = in_tx != null ? in_tx + in_width / 2 : in_width / 2;
		ty = in_ty != null ? in_ty + in_height / 2 : in_height / 2;
		
	}
	
	
	public function deltaTransformPoint (point:Point):Point {
		
		return new Point (point.x * a + point.y * c, point.x * b + point.y * d);
		
	}
	
	
	public function identity ():Void {
		
		a = 1;
		b = 0;
		c = 0;
		d = 1;
		tx = 0;
		ty = 0;
		
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
		
		return this;
		
	}
	
	
	public function mult (m:Matrix):Matrix {	
		
		var result = new Matrix ();
		
		result.a = a * m.a + b * m.c;
		result.b = a * m.b + b * m.d;
		result.c = c * m.a + d * m.c;
		result.d = c * m.b + d * m.d;
		
		result.tx = tx * m.a + ty * m.c + m.tx;
		result.ty = tx * m.b + ty * m.d + m.ty;
		
		return result;
		
	}
	
	
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
	public function rotate (inTheta:Float):Void {
		
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
		
	}
	

	/*
		Scale object "after" other transforms
		
		[  a  b   0 ][  sx  0   0 ]
		[  c  d   0 ][  0   sy  0 ]
		[  tx ty  1 ][  0   0   1 ]
	*/
	public function scale (inSX:Float, inSY:Float):Void {
		
		a *= inSX;
		b *= inSY;
		
		c *= inSX;
		d *= inSY;
		
		tx *= inSX;
		ty *= inSY;
		
	}
	
	
	public function setRotation (inTheta:Float, ?inScale:Float):Void {
		
		var scale:Float = inScale == null ? 1.0 : inScale;
		a = Math.cos(inTheta) * scale;
		c = Math.sin(inTheta) * scale;
		b = -c;
		d = a;
		
	}
	
	
	public function transformPoint (inPos:Point):Point {
		
		return new Point (inPos.x * a + inPos.y * c + tx, inPos.x * b + inPos.y * d + ty);
		
	}
	
	
	public function translate (inDX:Float, inDY:Float):Void {	
		
		tx += inDX;
		ty += inDY;
		
	}
	
	
}