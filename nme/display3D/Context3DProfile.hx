package nme.display3D;
#if (cpp || neko)

enum Context3DProfile 
{
   BASELINE;
   BASELINE_CONSTRAINED;
   BASELINE_EXTENDED;
}

#else
typedef Context3DProfile = flash.display3D.Context3DProfile;
#end