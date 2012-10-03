/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash.geom;
import jeash.geom.Point;


/*

   Contrary to any adobe documentation , points transform with:


   [ X'  Y'  ]   =  [ X  Y  1 ] [  a   b ]
   [  c   d ]
   [  tx  ty]


 */

class Matrix
{
	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx(default, setTx):Float;
	public var ty(default, setTy):Float;

	public var _sx:Float;
	public var _sy:Float;

	public function new(?in_a : Float, ?in_b : Float, ?in_c : Float, ?in_d : Float,
			?in_tx : Float, ?in_ty : Float)
	{
		a = in_a==null ? 1.0 : in_a;
		b = in_b==null ? 0.0 : in_b;
		c = in_c==null ? 0.0 : in_c;
		d = in_d==null ? 1.0 : in_d;
		tx = in_tx==null ? 0.0 : in_tx;
		ty = in_ty==null ? 0.0 : in_ty;
		_sx = 1.0;
		_sy = 1.0;
	}


	public inline function clone() {
		var m = new Matrix(a,b,c,d,tx,ty);
		m._sx = _sx;
		m._sy = _sy;
		return m;
	}

	public function copy(m:Matrix) {
		a = m.a;
		b = m.b;
		c = m.c;
		d = m.d;
		tx = m.tx;
		ty = m.ty;
		_sx = m._sx;
		_sy = m._sy;
	}

	public function createGradientBox(in_width : Float, in_height : Float,
			?rotation : Float, ?in_tx : Float, ?in_ty : Float) : Void
	{
		a = in_width/1638.4;
		d = in_height/1638.4;

		// rotation is clockwise
		if (rotation != null && rotation != 0.0) {
			var cos = Math.cos(rotation);
			var sin = Math.sin(rotation);
			b = sin*d;
			c = -sin*a;
			a *= cos;
			d *= cos;
		} else {
			b = c = 0;
		}

		tx = in_tx!=null ? in_tx+in_width/2 : in_width/2;
		ty = in_ty!=null ? in_ty+in_height/2 : in_height/2;
	}

	private inline function setRotation(inTheta:Float,?inScale:Float) {
		var scale:Float = inScale==null ? 1.0 : inScale;
		a = Math.cos(inTheta)*scale;
		c = Math.sin(inTheta)*scale;
		b = -c;
		d = a;
		cleanValues();
	}

	public function invert():Matrix {
		var norm = a*d-b*c;
		if (norm == 0) {
			a = b = c = d = 0;
			tx=-tx;
			ty=-ty;
		} else {
			norm = 1.0/norm;
			var a1 = d*norm;
			d = a*norm;
			a = a1;
			b*=-norm;
			c*=-norm;

			var tx1 = - a*tx - c*ty; 
			ty = - b*tx - d*ty; 
			tx = tx1;
		}
		_sx /= _sx;
		_sy /= _sy;
		cleanValues();
		return this;
	}

	public inline function jeashTransformX(inPos:Point):Float {
		return inPos.x * a + inPos.y * c + tx;
	}

	public inline function jeashTransformY(inPos:Point):Float {
		return inPos.x * b + inPos.y * d + ty;
	}

	public function transformPoint(inPos:Point) {
		return new Point(jeashTransformX(inPos), jeashTransformY(inPos));
	}

	public inline function jeashTranslateTransformed(inPos:Point):Void {
		tx = jeashTransformX(inPos);
		ty = jeashTransformY(inPos);
		cleanValues();
	}

	public function translate(inDX:Float, inDY:Float) {
		var m = new Matrix();
		m.tx = inDX;
		m.ty = inDY;
		this.concat(m);
	}

	private function setTx(inValue:Float):Float {
		tx = inValue;// * _sx;
		return tx;
	}
	private function setTy(inValue:Float):Float {
		ty = inValue;// * _sy;
		return ty;
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

	public function rotate(inTheta:Float) {
		var cos = Math.cos(inTheta);
		var sin = Math.sin(inTheta);

		var a1 = a*cos - b*sin;
		b = a*sin + b*cos;
		a = a1;

		var c1 = c*cos - d*sin;
		d = c*sin + d*cos;
		c = c1;

		var tx1 = tx*cos - ty*sin;
		ty = tx*sin + ty*cos;
		tx = tx1;
		cleanValues();
	}



	/*

	   Scale object "after" other transforms

	   [  a  b   0 ][  sx  0   0 ]
	   [  c  d   0 ][  0   sy  0 ]
	   [  tx ty  1 ][  0   0   1 ]
	 */
	public function scale(inSX:Float, inSY:Float) {
		_sx = inSX;
		_sy = inSY;
		a *= inSX;
		b *= inSY;
		c *= inSX;
		d *= inSY;
		tx *= inSX;
		ty *= inSY;
		cleanValues();
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
	public function concat(m:Matrix) {
		var a1 = a*m.a + b*m.c;
		b = a*m.b + b*m.d;
		a = a1;

		var c1 = c*m.a + d*m.c;
		d = c*m.b + d*m.d;
		c = c1;

		var tx1 = tx*m.a + ty*m.c + m.tx;
		ty = tx*m.b + ty*m.d + m.ty;
		tx = tx1;
		_sx *= m._sx;
		_sy *= m._sy;
		cleanValues();
	}

	private inline function cleanValues():Void {
		a = Math.round(a * 1000) / 1000;
		b = Math.round(b * 1000) / 1000;
		c = Math.round(c * 1000) / 1000;
		d = Math.round(d * 1000) / 1000;
		tx = Math.round(tx * 10) / 10;
		ty = Math.round(ty * 10) / 10;
	}

	public inline function mult(m:Matrix) {
		var result = clone();
		result.concat(m);
		return result;
	}

	public function identity() {
		a = 1;
		b = 0;
		c = 0;
		d = 1;
		tx = 0;
		ty = 0;
		_sx = 1.0;
		_sy = 1.0;
	}

	public inline function toMozString() {
		#if js
		var m = "matrix(";
		m += a; m += ", ";
		m += b; m += ", ";
		m += c; m += ", ";
		m += d; m += ", ";
		m += tx; m += "px, ";
		m += ty; m += "px)";
		return m;
		#end
	}

	public inline function toString() {
		#if js
		var m = "matrix(";
		m += a; m += ", ";
		m += b; m += ", ";
		m += c; m += ", ";
		m += d; m += ", ";
		m += tx; m += ", ";
		m += ty; m += ")";
		return m;
		#end
	}

	public inline function to3DString() {
		// identityMatrix
		//  [a,b,tx,0],
		//  [c,d,ty,0],
		//  [0,0,1, 0],
		//  [0,0,0, 1]
		//
		// matrix3d(a,       b, 0, 0, c, d,       0, 0, 0, 0, 1, 0, tx,     ty, 0, 1)
		#if js
		var m = "matrix3d(";
		m += a; m += ", ";
		m += b; m += ", ";
		m += "0, 0, ";
		m += c; m += ", ";
		m += d; m += ", ";
		m += "0, 0, 0, 0, 1, 0, ";
		m += tx; m += ", ";
		m += ty; m += ", ";
		m += "0, 1";
		m += ")";
		return m;
		#end
	}

}

