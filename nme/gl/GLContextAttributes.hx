package nme.gl;
#if display


typedef GLContextAttributes = {
	
    alpha:Bool, 
    depth:Bool,
    stencil:Bool,
    antialias:Bool,
    premultipliedAlpha:Bool,
    preserveDrawingBuffer:Bool,
	
};


#elseif (cpp || neko)
typedef GLContextAttributes = native.gl.GLContextAttributes;
#elseif js
typedef GLContextAttributes = browser.gl.GLContextAttributes;
#end