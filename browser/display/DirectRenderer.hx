package browser.display;
#if js


import browser.geom.Rectangle;
import browser.geom.Matrix;
import browser.gl.GL;
import browser.Html5Dom;


class DirectRenderer extends DisplayObject {
	
	
	private var nmeContext:WebGLRenderingContext;
	private var nmeGraphics:Graphics;
	
	
	public function new(inType:String = "DirectRenderer") {
		
		super();
		
		nmeGraphics = new Graphics();
		
		if (inType == "OpenGLView" && nmeGraphics != null) {
			
			nmeContext = nmeGraphics.nmeSurface.getContext ("webgl");
			
			if (nmeContext == null) {
				
				nmeContext = nmeGraphics.nmeSurface.getContext ("experimental-webgl");
				
			}
			
		}
		
	}
	
	
	public override function nmeGetGraphics():Graphics {
		
		return nmeGraphics;
		
	}
	
	
	private override function nmeRender(inMask:HTMLCanvasElement = null, clipRect:Rectangle = null) {
		
		if (!nmeCombinedVisible) return;
		
		var gfx = nmeGetGraphics();
		if (gfx == null) return;
		
		if (_matrixInvalid || _matrixChainInvalid) nmeValidateMatrix();
		
		nmeInvalidateBounds();
		validateBounds();
		
		var fullAlpha:Float = (parent != null ? parent.nmeCombinedAlpha : 1) * alpha;
		
		if (nmeBoundsRect.width == 0 || nmeBoundsRect.height == 0) fullAlpha = 0;
		
		Lib.nmeSetSurfaceOpacity(gfx.nmeSurface, fullAlpha);
		
		// handle transform, don't apply transform to each frame?
		
		gfx.nmeSurface.width = Math.ceil (nmeBoundsRect.width);
		gfx.nmeSurface.height = Math.ceil (nmeBoundsRect.height);
		gfx.nmeSurface.style.left = (nmeBoundsRect.x) + "px";
		gfx.nmeSurface.style.top = (nmeBoundsRect.y) + "px";
		
		if (nmeContext != null) {
			
			GL.nmeContext = nmeContext;
			
			if (render != null) render(nmeBoundsRect);
			
		}
		
	}
	
	
	public dynamic function render(inRect:Rectangle) {
		
		
		
	}
	
	
	private override function validateBounds():Void {
		
		if (_boundsInvalid) {
			
			nmeBoundsRect = new Rectangle (nmeX, nmeY, nmeWidth, nmeHeight);
			nmeSetDimensions();
			
			nmeClearFlag(DisplayObject.BOUNDS_INVALID);
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private override function set_height(inValue:Float):Float {
		
		nmeSetFlag(DisplayObject.TRANSFORM_INVALID);
		
		return nmeHeight = inValue;
		
	}
	
	
	private override function set_width(inValue:Float):Float {
		
		nmeSetFlag(DisplayObject.TRANSFORM_INVALID);
		
		return nmeWidth = inValue;
		
	}
	
	
}


#end