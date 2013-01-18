package browser.display;
#if js


import browser.gl.GL;
import browser.geom.Matrix3D;
//import native.gl.GLInstance;


class OpenGLView extends DirectRenderer {
	

	public static inline var CONTEXT_LOST = "glcontextlost";
	public static inline var CONTEXT_RESTORED = "glcontextrestored";
	
	//var context:GLInstance;
	
	
	public function new() {
		
		super("OpenGLView");
		
	}
	
	
}


#end