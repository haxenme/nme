package nme.geom;
#if code_completion


extern class Transform {
	var colorTransform : ColorTransform;
	var concatenatedColorTransform(default,null) : ColorTransform;
	var concatenatedMatrix(default,null) : Matrix;
	var matrix : Matrix;
	@:require(flash10) var matrix3D : Matrix3D;
	//@:require(flash10) var perspectiveProjection : PerspectiveProjection;
	var pixelBounds(default,null) : Rectangle;
	function new(displayObject : nme.display.DisplayObject) : Void;
	@:require(flash10) function getRelativeMatrix3D(relativeTo : nme.display.DisplayObject) : Matrix3D;
}


#elseif (cpp || neko)
typedef Transform = neash.geom.Transform;
#elseif js
typedef Transform = jeash.geom.Transform;
#else
typedef Transform = flash.geom.Transform;
#end