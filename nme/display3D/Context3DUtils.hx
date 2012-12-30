package nme.display3D;

import nme.display3D.Context3DProgramType;
import nme.display3D.Program3D;
import nme.utils.ByteArray;
import nme.display.BitmapData;
import nme.display3D.textures.Texture;
#if cpp
import nme.gl.GL;
#end

class Context3DUtils {


    inline public static function createShader(
        #if flash
        type : Context3DProgramType,
        #elseif cpp
        type : Int,
        #end
        shaderSource : String) :
        #if flash
            flash.utils.ByteArray
        #elseif cpp
            nme.gl.Shader
        #end
        {
        #if flash
        var assembler = new com.adobe.utils.AGALMiniAssembler();
	    assembler.assemble(type, shaderSource);
	    return assembler.agalcode();
        #elseif cpp
        var shader = GL.createShader(type);
        GL.shaderSource(shader, shaderSource);
        GL.compileShader(shader);
        if (GL.getShaderParameter(shader, GL.COMPILE_STATUS)==0)
        {
            trace("--- ERR ---\n" + shaderSource);
            var err = GL.getShaderInfoLog(shader);
            if (err!="")
                throw err;
        }
        return shader;
        #end
    }


}