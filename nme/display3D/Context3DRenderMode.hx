package nme.display3D;
#if (cpp || neko)

enum Context3DRenderMode 
{
   AUTO;
   SOFTWARE;
}

#else
typedef Context3DRenderMode = flash.display3D.Context3DRenderMode;
#end