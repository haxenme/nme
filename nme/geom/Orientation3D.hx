#if flash


package nme.geom;


@:native ("flash.geom.Orientation3D")
@:fakeEnum(String) extern enum Orientation3D {
	AXIS_ANGLE;
	EULER_ANGLES;
	QUATERNION;
}


#end