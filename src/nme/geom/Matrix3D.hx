package nme.geom;
#if (!flash)

import nme.Vector;

/*

      [ 0  1  2  3  ]
  m = [ 4  5  6  7  ]
      [ 8  9  10 11 ]
      [ 12 13 14 15 ]

  transformVector -> vector is a row on the left, matrix is on the right

   1x4 * 4x4 -> 1x4

                          [ Vx Vy Vz 1 ] x [ 0  1  2  3  ]
 V' = [V'x V'y V'z w ] =                   [ 4  5  6  7  ]
                                           [ 8  9  10 11 ]
                                           [ 12 13 14 15 ]

  Appending a transform is transforming the result:

 V" = Transform( V' )
    = [ V ] x [ m ] x [ Transform ]
    = [ V ] x  m.append(Transform)

  Prepending a transform is transforming vector before the matrix

 V" = Transform(V) x [ m ]
    = V x [Transform] x [ m ]
    = V x m.prepend(Transform)
    = V x Transform.append(m)

 A typical 3D pipeline has:
  object vectors in its own cordinates (O),
  then a placement matrix to move the object, P,
  then a view matrix that depends on the eye position, view
  then a projection matix that depends on field of view and screen aspect, proj

 shaderPos = O x P x view x proj
           = O x P x mvp

  mvp = view.append(proj)
  obj = mvp.prepend(P), or P.append(mvp)



*/


@:nativeProperty
class Matrix3D 
{
   public var determinant(get, null):Float;
   public var position(get, set):Vector3D;
   public var rawData:Vector<Float>;

   public var mxx(get,set):Float; public inline function get_mxx() return rawData[0]; public inline function set_mxx(m) return rawData[0]=m;
   public var myx(get,set):Float; public inline function get_myx() return rawData[1]; public inline function set_myx(m) return rawData[1]=m;
   public var mzx(get,set):Float; public inline function get_mzx() return rawData[2]; public inline function set_mzx(m) return rawData[2]=m;
   public var mwx(get,set):Float; public inline function get_mwx() return rawData[3]; public inline function set_mwx(m) return rawData[3]=m;

   public var mxy(get,set):Float; public inline function get_mxy() return rawData[4]; public inline function set_mxy(m) return rawData[4]=m;
   public var myy(get,set):Float; public inline function get_myy() return rawData[5]; public inline function set_myy(m) return rawData[5]=m;
   public var mzy(get,set):Float; public inline function get_mzy() return rawData[6]; public inline function set_mzy(m) return rawData[6]=m;
   public var mwy(get,set):Float; public inline function get_mwy() return rawData[7]; public inline function set_mwy(m) return rawData[7]=m;

   public var mxz(get,set):Float; public inline function get_mxz() return rawData[8]; public inline function set_mxz(m) return rawData[8]=m;
   public var myz(get,set):Float; public inline function get_myz() return rawData[9]; public inline function set_myz(m) return rawData[9]=m;
   public var mzz(get,set):Float; public inline function get_mzz() return rawData[10]; public inline function set_mzz(m) return rawData[10]=m;
   public var mwz(get,set):Float; public inline function get_mwz() return rawData[11]; public inline function set_mwz(m) return rawData[11]=m;

   public var tx(get,set):Float; public inline function get_tx() return rawData[12]; public inline function set_tx(m) return rawData[12]=m;
   public var ty(get,set):Float; public inline function get_ty() return rawData[13]; public inline function set_ty(m) return rawData[13]=m;
   public var tz(get,set):Float; public inline function get_tz() return rawData[14]; public inline function set_tz(m) return rawData[14]=m;
   public var tw(get,set):Float; public inline function get_tw() return rawData[15]; public inline function set_tw(m) return rawData[15]=m;

   public function new(?v:Vector<Float>) 
   {
      if (v != null && v.length == 16) 
      {
         rawData = v;

      } else 
      {
         rawData = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];
      }
   }

   public function append(lhs:Matrix3D):Void 
   {
      var m111:Float = this.rawData[0], m121:Float = this.rawData[4], m131:Float = this.rawData[8], m141:Float = this.rawData[12],
         m112:Float = this.rawData[1], m122:Float = this.rawData[5], m132:Float = this.rawData[9], m142:Float = this.rawData[13],
         m113:Float = this.rawData[2], m123:Float = this.rawData[6], m133:Float = this.rawData[10], m143:Float = this.rawData[14],
         m114:Float = this.rawData[3], m124:Float = this.rawData[7], m134:Float = this.rawData[11], m144:Float = this.rawData[15],
         m211:Float = lhs.rawData[0], m221:Float = lhs.rawData[4], m231:Float = lhs.rawData[8], m241:Float = lhs.rawData[12],
         m212:Float = lhs.rawData[1], m222:Float = lhs.rawData[5], m232:Float = lhs.rawData[9], m242:Float = lhs.rawData[13],
         m213:Float = lhs.rawData[2], m223:Float = lhs.rawData[6], m233:Float = lhs.rawData[10], m243:Float = lhs.rawData[14],
         m214:Float = lhs.rawData[3], m224:Float = lhs.rawData[7], m234:Float = lhs.rawData[11], m244:Float = lhs.rawData[15];

      rawData[0] = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
      rawData[1] = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
      rawData[2] = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
      rawData[3] = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;

      rawData[4] = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
      rawData[5] = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
      rawData[6] = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
      rawData[7] = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;

      rawData[8] = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
      rawData[9] = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
      rawData[10] = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
      rawData[11] = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;

      rawData[12] = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
      rawData[13] = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
      rawData[14] = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
      rawData[15] = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;
   }


   public function appendRotation(degrees:Float, axis:Vector3D, ?pivotPoint:Vector3D):Void 
   {
      var p0 = pivotPoint==null ? null : transformVector(pivotPoint);

      var m = getAxisRotation(axis.x, axis.y, axis.z, degrees);

      this.append(m);

      if (p0 != null) 
      {
         var p = transformVector(pivotPoint);
         appendTranslation(p0.x-p.x, p0.y-p.y, p0.z-p.z);
      }

   }

   public function appendRadians(radians:Float, axis:Vector3D, ?pivotPoint:Vector3D):Matrix3D 
   {
      appendRotation( radians*180/Math.PI, axis, pivotPoint);
      return this;
   }


   inline public function appendScale(xScale:Float, yScale:Float, zScale:Float):Void 
   {
      this.append(new Matrix3D([xScale, 0.0, 0.0, 0.0, 0.0, yScale, 0.0, 0.0, 0.0, 0.0, zScale, 0.0, 0.0, 0.0, 0.0, 1.0]));
   }

   inline public function appendTranslation(x:Float, y:Float, z:Float):Void 
   {
      rawData[12] += x;
      rawData[13] += y;
      rawData[14] += z;
   }

   inline public function clone():Matrix3D 
   {
      return new Matrix3D(this.rawData.copy());
   }

   public function copyColumnFrom (column:Int, vector3D:Vector3D):Void {
      
      switch( column ) {
      
         case 0:
            rawData[ 0 ] = vector3D.x;
            rawData[ 1 ] = vector3D.y;
            rawData[ 2 ] = vector3D.z;
            rawData[ 3 ] = vector3D.w;
         case 1:
            rawData[ 4 ] = vector3D.x;
            rawData[ 5 ] = vector3D.y;
            rawData[ 6 ] = vector3D.z;
            rawData[ 7 ] = vector3D.w;
         case 2:
            rawData[ 8 ] = vector3D.x;
            rawData[ 9 ] = vector3D.y;
            rawData[ 10 ] = vector3D.z;
            rawData[ 11 ] = vector3D.w;
         case 3:
            rawData[ 12 ] = vector3D.x;
            rawData[ 13 ] = vector3D.y;
            rawData[ 14 ] = vector3D.z;
            rawData[ 15 ] = vector3D.w;
         default:
            throw ( "Error, Column " + column + " out of bounds [0, ..., 3]");
      }
      
   }
   
   
   public function copyColumnTo (column:Int, vector3D:Vector3D):Void {

      switch( column )
      {
         case 0:
            vector3D.x = rawData[ 0 ];
            vector3D.y = rawData[ 1 ];
            vector3D.z = rawData[ 2 ];
            vector3D.w = rawData[ 3 ];
         case 1:
            vector3D.x = rawData[ 4 ];
            vector3D.y = rawData[ 5 ];
            vector3D.z = rawData[ 6 ];
            vector3D.w = rawData[ 7 ];
         case 2:
            vector3D.x = rawData[ 8 ];
            vector3D.y = rawData[ 9 ];
            vector3D.z = rawData[ 10 ];
            vector3D.w = rawData[ 11 ];
         case 3:
            vector3D.x = rawData[ 12 ];
            vector3D.y = rawData[ 13 ];
            vector3D.z = rawData[ 14 ];
            vector3D.w = rawData[ 15 ];
         default:
            throw ( "Error, Column " + column + " out of bounds [0, ..., 3]");
      }
      
   }


   public function copyFrom (other:Matrix3D):Void {

      rawData = other.rawData.copy();

   }

   public function copyRawDataFrom( vector:Vector<Float>, index:UInt = 0, transpose:Bool = false ) {
      
      if ( transpose )
         this.transpose();
     
      var l : UInt = vector.length - index;
      for ( c in 0...l )
         rawData[c] = vector[c+index];
     
      if ( transpose )
         this.transpose();

   }


   public function copyRawDataTo( vector:Vector<Float>, index:UInt = 0, transpose:Bool = false ) {

      if ( transpose )
         this.transpose();

      var l : UInt = rawData.length;
      for ( c in 0...l )
         vector[c + index ] = rawData[c];
      
      if ( transpose )
         this.transpose();

   }

   public function oglString(join='\n')
      return '[ $mxx $myx $mzx $mwz ]$join[ $mxy $myy $mzy $mwy ]$join[ $mxz $myz $mzz $mwz ]$join[ $tx $ty $tz $tw ]';


   public function copyRowFrom( row:UInt, vector3D:Vector3D ) {

      switch( row ) {

         case 0:
            rawData[ 0 ] = vector3D.x;
            rawData[ 4 ] = vector3D.y;
            rawData[ 8 ] = vector3D.z;
            rawData[ 12 ] = vector3D.w;
         
         case 1:
            rawData[ 1 ] = vector3D.x;
            rawData[ 5 ] = vector3D.y;
            rawData[ 9 ] = vector3D.z;
            rawData[ 13 ] = vector3D.w;
         
         case 2:
            rawData[ 2 ] = vector3D.x;
            rawData[ 6 ] = vector3D.y;
            rawData[ 10 ] = vector3D.z;
            rawData[ 14 ] = vector3D.w;
         
         case 3:
            rawData[ 3 ] = vector3D.x;
            rawData[ 7 ] = vector3D.y;
            rawData[ 11 ] = vector3D.z;
            rawData[ 15 ] = vector3D.w;
         
         default:
            throw ( "Error, Row " + row + " out of bounds [0, ..., 3]");
      }
      
   }
   




   public static function create2D(x:Float, y:Float, scale:Float = 1, rotation:Float = 0) 
   {
      var theta = rotation * Math.PI / 180.0;
      var c = Math.cos(theta);
      var s = Math.sin(theta);

      return new Matrix3D([
         c*scale,  -s*scale, 0,  0,
         s*scale,  c*scale, 0,  0,
         0,        0,        1,  0,
         x,        y,        0,  1
      ]);
   }

   public static function createABCD(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float) 
   {
      return new Matrix3D([
         a, b, 0, 0,
         c, d, 0, 0,
         0, 0, 1, 0,
         tx,ty,0, 1
      ]);
   }

   public static function createOrtho(x0:Float, x1:Float,  y0:Float, y1:Float, zNear:Float, zFar:Float) 
   {
      var sx = 1.0 / (x1 - x0);
      var sy = 1.0 / (y1 - y0);
      var sz = 1.0 / (zFar - zNear);

      return new Matrix3D([
         2.0*sx,       0,          0,                 0,
         0,            2.0*sy,     0,                 0,
         0,            0,          -2.0*sz,           0,
         - (x0+x1)*sx, - (y0+y1)*sy, - (zNear+zFar)*sz,  1,
      ]);
   }

   public function removeScaleAndPosition() : Vector<Vector3D>
   {
      var pos = new Vector3D(rawData[12], rawData[13], rawData[14]);
      rawData[12] = 0;
      rawData[13] = 0;
      rawData[14] = 0;

      var scale = new Vector3D();

      scale.x = Math.sqrt(rawData[0] * rawData[0] + rawData[1] * rawData[1] + rawData[2] * rawData[2]);
      scale.y = Math.sqrt(rawData[4] * rawData[4] + rawData[5] * rawData[5] + rawData[6] * rawData[6]);
      scale.z = Math.sqrt(rawData[8] * rawData[8] + rawData[9] * rawData[9] + rawData[10] * rawData[10]);

      if (rawData[0] * (rawData[5] * rawData[10] - rawData[6] * rawData[9]) - rawData[1] * (rawData[4] * rawData[10] - rawData[6] * rawData[8]) + rawData[2] * (rawData[4] * rawData[9] - rawData[5] * rawData[8]) < 0) 
      {
         scale.z = -scale.z;
      }

      rawData[0] /= scale.x; 
      rawData[1] /= scale.x; 
      rawData[2] /= scale.x; 
      rawData[4] /= scale.y; 
      rawData[5] /= scale.y; 
      rawData[6] /= scale.y; 
      rawData[8] /= scale.z; 
      rawData[9] /= scale.z; 
      rawData[10] /= scale.z;

      var result = new Vector<Vector3D>(2);
      result[0] = pos;
      result[1] = scale;
      return result;
   }

   public function decompose():Vector<Vector3D> 
   {
      var m = clone();
      var ps = m.removeScaleAndPosition();
      var mr = m.rawData;

      var rot = new Vector3D();

      rot.y = Math.asin( -mr[2]);

      var C = Math.cos(rot.y);
      if (Math.abs(C) > 1e-5) 
      {
         rot.x = Math.atan2(mr[6], mr[10]);
         rot.z = Math.atan2(mr[1], mr[0]);
      }
      else
      {
         rot.z = 0;
         rot.x = Math.atan2(mr[4], mr[5]);
      }

      ps.insertAt(1,rot);

      return ps;
   }

   // Assumed scaled
   public function calculateQuaternion():Vector3D
   {
      var q = new Vector3D();

      var tr = mxx + myy + mzz;

      if (tr > 0)
      {
        var S = Math.sqrt(tr+1.0) * 2; // S=4*qw 
        q.w = 0.25 * S;
        q.x = (mzy - myz) / S;
        q.y = (mxz - mzx) / S;
        q.z = (myx - mxy) / S;
      }
      else if ((mxx > myy)&&(mxx > mzz))
      {
        var S = Math.sqrt(1.0 + mxx - myy - mzz) * 2; // S=4*qx 
        q.w = (mzy - myz) / S;
        q.x = 0.25 * S;
        q.y = (mxy + myx) / S;
        q.z = (mxz + mzx) / S;
      }
      else if (myy > mzz)
      {
        var S = Math.sqrt(1.0 + myy - mxx - mzz) * 2; // S=4*qy
        q.w = (mxz - mzx) / S;
        q.x = (mxy + myx) / S;
        q.y = 0.25 * S;
        q.z = (myz + mzy) / S;
      }
      else
      {
        var S = Math.sqrt(1.0 + mzz - mxx - myy) * 2; // S=4*qz
        q.w = (myx - mxy) / S;
        q.x = (mxz + mzx) / S;
        q.y = (myz + mzy) / S;
        q.z = 0.25 * S;
      }
      return q;
   }

   public function decomposeQuaternion():Array<Vector3D> 
   {
      var m = clone();
      var ps = m.removeScaleAndPosition();
      var q = m.calculateQuaternion();
      ps.insertAt(1,q);
      return ps;
   }

   public static function fromQuaternion(q:Vector3D)
   {
      var m = new Matrix3D();

      var sqw = q.w*q.w;
      var sqx = q.x*q.x;
      var sqy = q.y*q.y;
      var sqz = q.z*q.z;

      m.mxx = ( sqx - sqy - sqz + sqw);
      m.myy = (-sqx + sqy - sqz + sqw);
      m.mzz = (-sqx - sqy + sqz + sqw);

      var tmp1 = q.x*q.y;
      var tmp2 = q.z*q.w;
      m.myx = 2.0 * (tmp1 + tmp2);
      m.mxy = 2.0 * (tmp1 - tmp2);

      tmp1 = q.x*q.z;
      tmp2 = q.y*q.w;
      m.mzx = 2.0 * (tmp1 - tmp2);
      m.mxz = 2.0 * (tmp1 + tmp2);
      tmp1 = q.y*q.z;
      tmp2 = q.x*q.w;
      m.mzy = 2.0 * (tmp1 + tmp2);
      m.myz = 2.0 * (tmp1 - tmp2);
      return m;
   }

   public static function recomposeQuaternion(pqs:Vector<Vector3D>)
   {
      if (pqs[2]==null || pqs[2].x == 0 || pqs[2].y == 0 || pqs[2].z == 0)
         throw "recomposeQuaternion - expected [R,Q,S]";

      var mtx = Matrix3D.fromQuaternion(pqs[1]);

      mtx.prependScale(pqs[2].x, pqs[2].y, pqs[2].z);

      mtx.position = pqs[0];
      mtx.rawData[15] = 1;

      return mtx;
   }



   inline public function originTransform():Vector3D 
   {
      return new Vector3D( tx, ty, tz, tw );
   }

   inline public function deltaTransformVector(v:Vector3D):Vector3D 
   {
      var x:Float = v.x, y:Float = v.y, z:Float = v.z;
      return new Vector3D(
         (x * rawData[0] + y * rawData[1] + z * rawData[2] + rawData[3]),
         (x * rawData[4] + y * rawData[5] + z * rawData[6] + rawData[7]),
         (x * rawData[8] + y * rawData[9] + z * rawData[10] + rawData[11]),
      0);
   }

   inline public function linearTransformVector(v:Vector3D):Vector3D 
   {
      var x:Float = v.x, y:Float = v.y, z:Float = v.z;
      return new Vector3D(
         x * rawData[0] + y * rawData[4] + z * rawData[8],
         x * rawData[1] + y * rawData[5] + z * rawData[9],
         x * rawData[2] + y * rawData[6] + z * rawData[10],
      1);
   }


   inline static public function getAxisRotation(x:Float, y:Float, z:Float, degrees:Float):Matrix3D 
   {
      var m = new Matrix3D();

      var a1 = new Vector3D(x, y, z);
      var rad = -degrees * (Math.PI / 180);
      var c:Float = Math.cos(rad);
      var s:Float = Math.sin(rad);
      var t:Float = 1.0 - c;

      m.rawData[0] = c + a1.x * a1.x * t;
      m.rawData[5] = c + a1.y * a1.y * t;
      m.rawData[10] = c + a1.z * a1.z * t;

      var tmp1 = a1.x * a1.y * t;
      var tmp2 = a1.z * s;
      m.rawData[4] = tmp1 + tmp2;
      m.rawData[1] = tmp1 - tmp2;
      tmp1 = a1.x * a1.z * t;
      tmp2 = a1.y * s;
      m.rawData[8] = tmp1 - tmp2;
      m.rawData[2] = tmp1 + tmp2;
      tmp1 = a1.y * a1.z * t;
      tmp2 = a1.x*s;
      m.rawData[9] = tmp1 + tmp2;
      m.rawData[6] = tmp1 - tmp2;

      return m;
   }

   inline public function identity():Void 
   {
      rawData[0] = 1;
      rawData[1] = 0;
      rawData[2] = 0;
      rawData[3] = 0;
      rawData[4] = 0;
      rawData[5] = 1;
      rawData[6] = 0;
      rawData[7] = 0;
      rawData[8] = 0;
      rawData[9] = 0;
      rawData[10] = 1;
      rawData[11] = 0;
      rawData[12] = 0;
      rawData[13] = 0;
      rawData[14] = 0;
      rawData[15] = 1;
   }

   inline public static function interpolate(thisMat:Matrix3D, toMat:Matrix3D, percent:Float):Matrix3D 
   {
      var m = new Matrix3D();

      for(i in 0...16) 
      {
         m.rawData[i] = thisMat.rawData[i] + (toMat.rawData[i] - thisMat.rawData[i]) * percent;
      }

      return m;
   }

   inline public function interpolateTo(toMat:Matrix3D, percent:Float):Void 
   {
      for(i in 0...16) 
      {
         rawData[i] = rawData[i] + (toMat.rawData[i] - rawData[i]) * percent;
      }
   }

   inline public function invert(minDet = 1e-11):Bool 
   {
      var d = determinant;
      var invertable = Math.abs(d) > minDet;

      if (invertable) 
      {
         d = -1 / d;
         var m11:Float = rawData[0]; var m21:Float = rawData[4]; var m31:Float = rawData[8]; var m41:Float = rawData[12];
         var m12:Float = rawData[1]; var m22:Float = rawData[5]; var m32:Float = rawData[9]; var m42:Float = rawData[13];
         var m13:Float = rawData[2]; var m23:Float = rawData[6]; var m33:Float = rawData[10]; var m43:Float = rawData[14];
         var m14:Float = rawData[3]; var m24:Float = rawData[7]; var m34:Float = rawData[11]; var m44:Float = rawData[15];

         rawData[0] = d * (m22 * (m33 * m44 - m43 * m34) - m32 * (m23 * m44 - m43 * m24) + m42 * (m23 * m34 - m33 * m24));
         rawData[1] = -d * (m12 * (m33 * m44 - m43 * m34) - m32 * (m13 * m44 - m43 * m14) + m42 * (m13 * m34 - m33 * m14));
         rawData[2] = d * (m12 * (m23 * m44 - m43 * m24) - m22 * (m13 * m44 - m43 * m14) + m42 * (m13 * m24 - m23 * m14));
         rawData[3] = -d * (m12 * (m23 * m34 - m33 * m24) - m22 * (m13 * m34 - m33 * m14) + m32 * (m13 * m24 - m23 * m14));
         rawData[4] = -d * (m21 * (m33 * m44 - m43 * m34) - m31 * (m23 * m44 - m43 * m24) + m41 * (m23 * m34 - m33 * m24));
         rawData[5] = d * (m11 * (m33 * m44 - m43 * m34) - m31 * (m13 * m44 - m43 * m14) + m41 * (m13 * m34 - m33 * m14));
         rawData[6] = -d * (m11 * (m23 * m44 - m43 * m24) - m21 * (m13 * m44 - m43 * m14) + m41 * (m13 * m24 - m23 * m14));
         rawData[7] = d * (m11 * (m23 * m34 - m33 * m24) - m21 * (m13 * m34 - m33 * m14) + m31 * (m13 * m24 - m23 * m14));
         rawData[8] = d * (m21 * (m32 * m44 - m42 * m34) - m31 * (m22 * m44 - m42 * m24) + m41 * (m22 * m34 - m32 * m24));
         rawData[9] = -d * (m11 * (m32 * m44 - m42 * m34) - m31 * (m12 * m44 - m42 * m14) + m41 * (m12 * m34 - m32 * m14));
         rawData[10] = d * (m11 * (m22 * m44 - m42 * m24) - m21 * (m12 * m44 - m42 * m14) + m41 * (m12 * m24 - m22 * m14));
         rawData[11] = -d * (m11 * (m22 * m34 - m32 * m24) - m21 * (m12 * m34 - m32 * m14) + m31 * (m12 * m24 - m22 * m14));
         rawData[12] = -d * (m21 * (m32 * m43 - m42 * m33) - m31 * (m22 * m43 - m42 * m23) + m41 * (m22 * m33 - m32 * m23));
         rawData[13] = d * (m11 * (m32 * m43 - m42 * m33) - m31 * (m12 * m43 - m42 * m13) + m41 * (m12 * m33 - m32 * m13));
         rawData[14] = -d * (m11 * (m22 * m43 - m42 * m23) - m21 * (m12 * m43 - m42 * m13) + m41 * (m12 * m23 - m22 * m13));
         rawData[15] = d * (m11 * (m22 * m33 - m32 * m23) - m21 * (m12 * m33 - m32 * m13) + m31 * (m12 * m23 - m22 * m13));
      }

      return invertable;
   }

   public function inverse() : Matrix3D
   {
      var inv = clone();
      if (inv.invert())
         return inv;
      return null;
   }


   /*public function pointAt(pos:Vector3D, ?at:Vector3D, ?up:Vector3D):Void {
      if (at == null) at = new Vector3D(0,0,-1);
      if (up == null) up = new Vector3D(0,-1,0);

      //pos.x*=-1;
      //pos.y*=-1;
      //pos.z*=-1;
      //at.x*=-1;
      //at.y*=-1;
      //at.z*=-1;
      //up.x*=-1;
      //up.y*=-1;
      //up.z*=-1;
      var dir:Vector3D = at.subtract(pos);
      var vup:Vector3D = up.clone();
      var right:Vector3D;

      dir.normalize();
      vup.normalize();

      var dir2 = dir.clone();
      dir2.scaleBy(vup.dotProduct(dir));

      vup = vup.subtract(dir2);

      if (vup.length > 0)
      {
         vup.normalize();
      } else 
      {
         vup = dir.x != 0 ? new Vector3D(-dir.y,dir.x,0) : new Vector3D(1,0,0);
      }

      right = vup.crossProduct(dir);
      right.normalize();

      rawData[0] = right.x;
      rawData[4] = right.y;
      rawData[8] = right.z;
      rawData[12] = 0.0;
      rawData[1] = vup.x;
      rawData[5] = vup.y;
      rawData[9] = vup.z;
      rawData[13] = 0.0;
      rawData[2] = dir.x;
      rawData[6] = dir.y;
      rawData[10] = dir.z;
      rawData[14] = 0.0;
      rawData[3] = pos.x;
      rawData[7] = pos.y;
      rawData[11] = pos.z;
      rawData[15] = 1.0;
   }*/

   inline public function prepend(rhs:Matrix3D):Void 
   {
      var m111:Float = rhs.rawData[0], m121:Float = rhs.rawData[4], m131:Float = rhs.rawData[8], m141:Float = rhs.rawData[12],
         m112:Float = rhs.rawData[1], m122:Float = rhs.rawData[5], m132:Float = rhs.rawData[9], m142:Float = rhs.rawData[13],
         m113:Float = rhs.rawData[2], m123:Float = rhs.rawData[6], m133:Float = rhs.rawData[10], m143:Float = rhs.rawData[14],
         m114:Float = rhs.rawData[3], m124:Float = rhs.rawData[7], m134:Float = rhs.rawData[11], m144:Float = rhs.rawData[15],
         m211:Float = this.rawData[0], m221:Float = this.rawData[4], m231:Float = this.rawData[8], m241:Float = this.rawData[12],
         m212:Float = this.rawData[1], m222:Float = this.rawData[5], m232:Float = this.rawData[9], m242:Float = this.rawData[13],
         m213:Float = this.rawData[2], m223:Float = this.rawData[6], m233:Float = this.rawData[10], m243:Float = this.rawData[14],
         m214:Float = this.rawData[3], m224:Float = this.rawData[7], m234:Float = this.rawData[11], m244:Float = this.rawData[15];

      rawData[0] = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
      rawData[1] = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
      rawData[2] = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
      rawData[3] = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;

      rawData[4] = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
      rawData[5] = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
      rawData[6] = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
      rawData[7] = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;

      rawData[8] = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
      rawData[9] = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
      rawData[10] = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
      rawData[11] = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;

      rawData[12] = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
      rawData[13] = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
      rawData[14] = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
      rawData[15] = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;
   }

   inline public function prependRotation(degrees:Float, axis:Vector3D, ?pivotPoint:Vector3D):Void 
   {
      var m = getAxisRotation(axis.x, axis.y, axis.z, degrees);

      if (pivotPoint != null) 
      {
         var p = pivotPoint;
         m.appendTranslation(p.x, p.y, p.z);
      }

      this.prepend(m);
   }

   inline public function prependScale(xScale:Float, yScale:Float, zScale:Float):Void 
   {
      this.prepend(new Matrix3D([xScale, 0.0, 0.0, 0.0, 0.0, yScale, 0.0, 0.0, 0.0, 0.0, zScale, 0.0, 0.0, 0.0, 0.0, 1.0]));
   }

   inline public function prependTranslation(x:Float, y:Float, z:Float):Void 
   {
      var m = new Matrix3D();
      m.position = new Vector3D(x, y, z);
      this.prepend(m);
   }

   public function recompose(components:Vector<Vector3D>):Bool 
   {
      if (components.length < 3 || components[2].x == 0 || components[2].y == 0 || components[2].z == 0) return false;

      this.identity();
      this.appendScale(components[2].x, components[2].y, components[2].z);

      var angle:Float;
      angle = -components[1].x;
      this.append(new Matrix3D([1, 0, 0, 0, 0, Math.cos(angle), -Math.sin(angle), 0, 0, Math.sin(angle), Math.cos(angle), 0, 0, 0, 0 , 0]));
      angle = -components[1].y;
      this.append(new Matrix3D([Math.cos(angle), 0, Math.sin(angle), 0, 0, 1, 0, 0, -Math.sin(angle), 0, Math.cos(angle), 0, 0, 0, 0, 0]));
      angle = -components[1].z;
      this.append(new Matrix3D([Math.cos(angle), -Math.sin(angle), 0, 0, Math.sin(angle), Math.cos(angle), 0, 0, 0, 0, 1, 0, 0, 0, 0, 0]));

      this.position = components[0];
      this.rawData[15] = 1;

      return true;
   }

   inline public function transformVector(v:Vector3D):Vector3D 
   {
      var x:Float = v.x, y:Float = v.y, z:Float = v.z;
      return new Vector3D(
         (x * rawData[0] + y * rawData[4] + z * rawData[8] + rawData[12]),
         (x * rawData[1] + y * rawData[5] + z * rawData[9] + rawData[13]),
         (x * rawData[2] + y * rawData[6] + z * rawData[10] + rawData[14]),
         (x * rawData[3] + y * rawData[7] + z * rawData[11] + rawData[15])
      );
   }


   public function transformVectors(vin:Vector<Float>, vout:Vector<Float>):Void 
   {
      var i = 0;
      while(i + 3 <= vin.length) 
      {
         var x:Float = vin[i], y:Float = vin[i + 1], z:Float = vin[i + 2];
         vout[i] = x * rawData[0] + y * rawData[4] + z * rawData[8] + rawData[12];
         vout[i + 1] = x * rawData[1] + y * rawData[5] + z * rawData[9] + rawData[13];
         vout[i + 2] = x * rawData[2] + y * rawData[6] + z * rawData[10] + rawData[14];
         i += 3;
      }
   }

   #if sys
   public function print(roundDown = 0.0)
   {
      if (roundDown>0)
      {
         var m = clone();
         for(i in 0...16)
            if ( Math.abs(m.rawData[i])<roundDown )
               m.rawData[i] = 0.0;
         m.print();
      }
      else
      {
         Sys.println('[ $mxx $mxy $mxz | $tx ]');
         Sys.println('[ $myx $myy $myz | $ty ]');
         Sys.println('[ $mzx $mzy $mzz | $tz ]');
         Sys.println('[ $mwx $mwy $mwz | $tw ]');
      }
   }
   #end

   inline public function transpose():Void 
   {
      var oRawData = rawData.copy();
      rawData[1] = oRawData[4];
      rawData[2] = oRawData[8];
      rawData[3] = oRawData[12];
      rawData[4] = oRawData[1];
      rawData[6] = oRawData[9];
      rawData[7] = oRawData[13];
      rawData[8] = oRawData[2];
      rawData[9] = oRawData[6];
      rawData[11] = oRawData[14];
      rawData[12] = oRawData[3];
      rawData[13] = oRawData[7];
      rawData[14] = oRawData[11];
   }

   // Getters & Setters
   /** @private */ inline public function get_determinant():Float {
      return   -1 * ((rawData[0] * rawData[5] - rawData[4] * rawData[1]) * (rawData[10] * rawData[15] - rawData[14] * rawData[11])
         - (rawData[0] * rawData[9] - rawData[8] * rawData[1]) * (rawData[6] * rawData[15] - rawData[14] * rawData[7])
         + (rawData[0] * rawData[13] - rawData[12] * rawData[1]) * (rawData[6] * rawData[11] - rawData[10] * rawData[7])
         + (rawData[4] * rawData[9] - rawData[8] * rawData[5]) * (rawData[2] * rawData[15] - rawData[14] * rawData[3])
         - (rawData[4] * rawData[13] - rawData[12] * rawData[5]) * (rawData[2] * rawData[11] - rawData[10] * rawData[3])
         + (rawData[8] * rawData[13] - rawData[12] * rawData[9]) * (rawData[2] * rawData[7] - rawData[6] * rawData[3]));
   }

   /** @private */ inline public function get_position():Vector3D {
      return new Vector3D(rawData[12], rawData[13], rawData[14]);
   }

   /** @private */ inline public function set_position(val:Vector3D):Vector3D {
      rawData[12] = val.x;
      rawData[13] = val.y;
      rawData[14] = val.z;
      return val;
   }
}

#else
typedef Matrix3D = flash.geom.Matrix3D;
#end
