package nme.display3D;
#if display


@:fakeEnum(String) extern enum Context3DProfile {
	BASELINE;
	BASELINE_CONSTRAINED;
	BASELINE_EXTENDED;
}


#elseif (cpp || neko)
typedef Context3DProfile = native.display3D.Context3DProfile;
#elseif js
typedef Context3DProfile = browser.display3D.Context3DProfile;
#elseif flash
typedef Context3DProfile = flash.display3D.Context3DProfile;
#end