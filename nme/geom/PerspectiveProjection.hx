#if flash


package nme.geom;


@:native ("flash.geom.PerspectiveProjection")
@:require(flash10) extern class PerspectiveProjection {
	var fieldOfView : Float;
	var focalLength : Float;
	var projectionCenter : Point;
	function new() : Void;
	function toMatrix3D() : Matrix3D;
}



#end