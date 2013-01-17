package nme.display3D.shaders;

#if flash
typedef Shader = flash.utils.ByteArray;
#elseif cpp
import native.gl.GL;
typedef Shader = native.gl.Shader;
#end