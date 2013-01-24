package nme.display3D.shaders;

#if flash
typedef Shader = flash.utils.ByteArray;
#elseif (cpp || neko)
import native.gl.GL;
typedef Shader = native.gl.GLShader;
#elseif js
import browser.gl.GL;
typedef Shader = browser.gl.GLShader;
 #end
