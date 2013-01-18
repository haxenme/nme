package nme.gl;
#if display


typedef GLUniformLocation = Dynamic;


#elseif (cpp || neko)
typedef GLUniformLocation = native.gl.GLUniformLocation;
#elseif js
typedef GLUniformLocation = browser.gl.GLUniformLocation;
#end