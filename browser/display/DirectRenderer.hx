package browser.display;
#if js


import browser.geom.Rectangle;
import browser.geom.Matrix;
import browser.gl.GL;
import browser.Lib;
import js.html.CanvasElement;


class DirectRenderer extends DisplayObject {
	
	
	public var render(get_render, set_render):Dynamic;
	
	private var nmeContext:WebGLRenderingContext;
	private var nmeGraphics:Graphics;
	private var nmeRenderMethod:Dynamic;
	
	
	public function new(inType:String = "DirectRenderer") {
		
		super();
		
		nmeGraphics = new Graphics();
		
		nmeGraphics.nmeSurface.width = Lib.current.stage.stageWidth;
		nmeGraphics.nmeSurface.height = Lib.current.stage.stageHeight;
		
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
	
	
	private override function nmeRender(inMask:CanvasElement = null, clipRect:Rectangle = null) {
		
		if (!nmeCombinedVisible) return;
		
		var gfx = nmeGetGraphics();
		if (gfx == null) return;
		
		gfx.nmeSurface.width = stage.stageWidth;
		gfx.nmeSurface.height = stage.stageHeight;
		
		if (nmeContext != null) {
			
			GL.nmeContext = nmeContext;
			
			var rect = null;
			
			if (scrollRect == null) {
				
				rect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
				
			} else {
				
				rect = new Rectangle(x + scrollRect.x, y + scrollRect.y, scrollRect.width, scrollRect.height);
				
			}
			
			if (render != null) render(rect);
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_render():Dynamic {
		
		return nmeRenderMethod;
		
	}
	
	
	private function set_render(value:Dynamic):Dynamic {
		
		nmeRenderMethod = value;
		nmeRender();
		
		return value;
		
	}
	
	
}


#end