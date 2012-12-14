package native.display;


import native.Loader;
import native.gl.GL;
import native.geom.Matrix3D;
//import native.gl.GLInstance;


class OpenGLView extends DirectRenderer {
	

	public static inline var CONTEXT_LOST = "glcontextlost";
	public static inline var CONTEXT_RESTORED = "glcontextrestored";
	
	//var context:GLInstance;
	
	
	public function new () {
		
		super ("OpenGLView");
		
	}
	
}