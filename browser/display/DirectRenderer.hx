package browser.display;
#if js


import browser.geom.Rectangle;
import browser.gl.GL;
import browser.Html5Dom;


class DirectRenderer extends DisplayObject {
	
	
	private var context:WebGLRenderingContext;
	
	
	public function new(inType:String = "DirectRenderer") {
		
		super();
		
		var gfx = nmeGetGraphics ();
		
		if (inType == "OpenGLView" && gfx != null) {
			
			context = gfx.nmeSurface.getContext ("webgl");
			
			if (context == null) {
				
				context = gfx.nmeSurface.getContext ("experimental-webgl");
				
			}
			
		}
		
	}
	
	
	private override function nmeRender(inMask:HTMLCanvasElement = null, clipRect:Rectangle = null) {
		
		//if (!nmeCombinedVisible) return;
		//
		//var gfx = nmeGetGraphics();
		//if (gfx == null) return;
		//
		//if (_matrixInvalid || _matrixChainInvalid) nmeValidateMatrix();
		//
		///*
		//var clip0:Point = null;
		//var clip1:Point = null;
		//var clip2:Point = null;
		//var clip3:Point = null;
		//if (clipRect != null) {
			//var topLeft = clipRect.topLeft;
			//var topRight = clipRect.topLeft.clone();
			//topRight.x += clipRect.width;
			//var bottomRight = clipRect.bottomRight;
			//var bottomLeft = clipRect.bottomRight.clone();
			//bottomLeft.x -= clipRect.width;
			//clip0 = this.globalToLocal(this.parent.localToGlobal(topLeft));
			//clip1 = this.globalToLocal(this.parent.localToGlobal(topRight));
			//clip2 = this.globalToLocal(this.parent.localToGlobal(bottomRight));
			//clip3 = this.globalToLocal(this.parent.localToGlobal(bottomLeft));
		//}
		//*/
		//
		//if (gfx.nmeRender(inMask, nmeFilters, 1, 1)) {
			//
			//handleGraphicsUpdated(gfx);
			//
		//}
		//
		//var fullAlpha:Float = (parent != null ? parent.nmeCombinedAlpha : 1) * alpha;
		//
		//if (inMask != null) {
			//
			//var m = getSurfaceTransform(gfx);
			//Lib.nmeDrawToSurface(gfx.nmeSurface, inMask, m, fullAlpha, clipRect);
			//
		//} else {
			//
			//if (nmeTestFlag(TRANSFORM_INVALID)) {
				//
				//var m = getSurfaceTransform(gfx);
				//Lib.nmeSetSurfaceTransform(gfx.nmeSurface, m);
				//nmeClearFlag(TRANSFORM_INVALID);
				//
			//}
			//
			//Lib.nmeSetSurfaceOpacity(gfx.nmeSurface, fullAlpha);
			//
			///*if (clipRect != null) {
				//var rect = new Rectangle();
				//rect.topLeft = this.globalToLocal(this.parent.localToGlobal(clipRect.topLeft));
				//rect.bottomRight = this.globalToLocal(this.parent.localToGlobal(clipRect.bottomRight));
				//Lib.nmeSetSurfaceClipping(gfx.nmeSurface, rect);
			//}*/
			//
		//}
		
		//if (render != null) render(new Rectangle(inRect.x, inRect.y, inRect.width, inRect.height));
		
		if (context != null) {
			
			GL.nmeContext = context;
			
			if (render != null) render(null);
			
		}
		
	}
	
	
	public dynamic function render(inRect:Rectangle) {
		
		
		
	}
	
	
}


#end