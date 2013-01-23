package browser.display;
#if js


import browser.geom.Rectangle;
import browser.geom.Matrix;
import browser.gl.GL;
import browser.Html5Dom;
import browser.Lib;


class DirectRenderer extends DisplayObject {
	
	
	private var nmeContext:WebGLRenderingContext;
	private var nmeGraphics:Graphics;
	
	
	public function new(inType:String = "DirectRenderer") {
		
		super();
		
		nmeGraphics = new Graphics();
		
		if (inType == "OpenGLView" && nmeGraphics != null) {
			
			nmeContext = nmeGraphics.nmeSurface.getContext("webgl");
			
			if (nmeContext == null) {
				
				nmeContext = nmeGraphics.nmeSurface.getContext("experimental-webgl");
				
			}
			
			#if debug
			nmeContext = untyped WebGLDebugUtils.makeDebugContext(nmeContext);
			#end
			
		}
		
	}
	
	
	public override function nmeGetGraphics():Graphics {
		
		return nmeGraphics;
		
	}
	
	
	private override function nmeRender(inMask:HTMLCanvasElement = null, clipRect:Rectangle = null) {
		
		if (!nmeCombinedVisible) return;
		
		var gfx = nmeGetGraphics();
		if (gfx == null) return;
		
		gfx.nmeSurface.width = stage.stageWidth;
		gfx.nmeSurface.height = stage.stageHeight;
		
		if (nmeContext != null) {
			
			GL.nmeContext = nmeContext;
			
			if (render != null) render(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
			
		}
		
	}
	
	
	public dynamic function render(inRect:Rectangle) {
		
		
		
	}
	
	
}


#end