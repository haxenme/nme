package native.display;


import native.Loader;


class GraphicsEndFill extends IGraphicsData {
	
	
	public function new () {
		
		super (nme_graphics_end_fill_create ());
		
	}
	
	
	private static var nme_graphics_end_fill_create = Loader.load ("nme_graphics_end_fill_create", 0);
	
	
}