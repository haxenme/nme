package browser.display;
#if js


import browser.gl.GL;
import browser.geom.Matrix3D;
import browser.Lib;
//import native.gl.GLInstance;


class OpenGLView extends DirectRenderer {
	

	public static inline var CONTEXT_LOST = "glcontextlost";
	public static inline var CONTEXT_RESTORED = "glcontextrestored";
	
	public static var isSupported(get_isSupported, null):Bool;
	
	//var context:GLInstance;
	
	
	public function new() {
		
		super("OpenGLView");
		
		GL.nmeContext = nmeContext;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_isSupported():Bool {
		
		if (untyped (!window.WebGLRenderingContext)) {
			
			return false;
			
		}
		
		var view = new OpenGLView ();
		
		if (view.nmeContext == null) {
			
			return false;
			
		}
		
		return true;
		
	}
	
	
}


#end