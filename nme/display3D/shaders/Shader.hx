package nme.display3D.shaders;

#if flash
typedef Shader = flash.utils.ByteArray;
#elseif (cpp || neko)
import nme.gl.GL;
typedef Shader = nme.gl.GLShader;
#elseif js
import browser.gl.GL;
typedef Shader = browser.gl.GLShader;
 #end
