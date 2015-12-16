package nme.display3D;
#if (!flash)

import nme.gl.GL;

enum Context3DProgramType 
{
   VERTEX;
   FRAGMENT;
}

#else
typedef Context3DProgramType = flash.display3D.Context3DProgramType;
#end
