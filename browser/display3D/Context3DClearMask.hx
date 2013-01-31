package browser.display3D;
#if js


import nme.gl.GL;


class Context3DClearMask {
	
	inline static public var ALL:Int = COLOR | DEPTH | STENCIL;
	inline static public var COLOR:Int = GL.COLOR_BUFFER_BIT;
	inline static public var DEPTH:Int = GL.DEPTH_BUFFER_BIT;
	inline static public var STENCIL:Int = GL.STENCIL_BUFFER_BIT;
	
}


#end