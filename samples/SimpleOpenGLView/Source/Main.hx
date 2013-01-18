import nme.display.OpenGLView;
import nme.display.Sprite;
import nme.geom.Rectangle;
import nme.gl.GL;


class Main extends Sprite {
	
	
	private var view:OpenGLView;
	
	
	public function new () {
		
		super ();
		
		if (OpenGLView.isSupported) {
			
			view = new OpenGLView ();
			view.render = renderView;
			addChild (view);
			
		}
		
	}
	
	
	private function renderView (rect:Rectangle):Void {
		
		GL.clearColor (0.0, 0.0, 0.0, 1.0);
		GL.enable (GL.DEPTH_TEST);
		GL.depthFunc (GL.LEQUAL);
		GL.clear (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
		
		
	}
	
	
}