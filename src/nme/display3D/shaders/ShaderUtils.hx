package nme.display3D.shaders;

#if (!flash || js)
import nme.gl.GL;
#elseif flash
import flash.utils.ByteArray;
import com.adobe.utils.AGALMiniAssembler;
#end

import nme.display3D.Context3DProgramType;

@:nativeProperty
class ShaderUtils{

    inline public static function createShader (type: Context3DProgramType, shaderSource:String): nme.display3D.shaders.Shader {

        #if flash

		var assembler = new AGALMiniAssembler ();
		assembler.assemble (cast(type,String), shaderSource);
		return assembler.agalcode;

		#elseif (!flash || js)

		var glType : Int;
        switch(type){
            case Context3DProgramType.VERTEX: glType = GL.VERTEX_SHADER;
            case Context3DProgramType.FRAGMENT: glType = GL.FRAGMENT_SHADER;
        }

		var shader = GL.createShader (glType);
		GL.shaderSource (shader, shaderSource);
		GL.compileShader (shader);

		if (GL.getShaderParameter (shader, GL.COMPILE_STATUS) == 0) {

			trace("--- ERR ---\n" + shaderSource);
			var err = GL.getShaderInfoLog (shader);
			if (err != "") throw err;

		}

		return shader;

		#else

        return null;

        #end

    }
}
