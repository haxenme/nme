package nme.display3D;


import nme.display3D.textures.Texture;
import nme.display3D.Context3DProgramType;
import nme.display3D.Program3D;
import nme.display.BitmapData;
import nme.utils.ByteArray;

#if flash
import com.adobe.utils.AGALMiniAssembler;
#else
import nme.gl.GL;
#end


class Context3DUtils {
	
	
	inline public static function createShader (type: #if flash Context3DProgramType #else Int #end, shaderSource:String): #if flash ByteArray #else Shader #end {
		
		#if flash
		
		var assembler = new AGALMiniAssembler ();
		assembler.assemble (type, shaderSource);
		return assembler.agalcode ();
		
		#elseif !js
		
		var shader = GL.createShader (type);
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