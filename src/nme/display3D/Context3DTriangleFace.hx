package nme.display3D;
#if (!flash)

import nme.gl.GL;

class Context3DTriangleFace 
{
   inline public static var BACK = GL.FRONT;
   inline public static var FRONT = GL.BACK;
   inline public static var FRONT_AND_BACK = GL.FRONT_AND_BACK;
   inline public static var NONE = 0;
}

#else
typedef Context3DTriangleFace = flash.display3D.Context3DTriangleFace;
#end
