package furusystems.display.gl.materials;
import furusystems.display.gl.materials.properties.uniforms.Uniform;
import furusystems.display.gl.materials.properties.uniforms.UniformF;
import furusystems.display.gl.materials.properties.uniforms.UniformF2;
import furusystems.display.gl.materials.properties.uniforms.UniformF3;
import furusystems.display.gl.materials.properties.uniforms.UniformF4;
import furusystems.display.gl.materials.properties.uniforms.UniformI;
import furusystems.display.gl.materials.properties.uniforms.UniformI2;
import furusystems.display.gl.materials.properties.uniforms.UniformI3;
import furusystems.display.gl.materials.properties.uniforms.UniformI4;
import furusystems.display.gl.materials.properties.uniforms.UniformM2;
import furusystems.display.gl.materials.properties.uniforms.UniformM3;
import furusystems.display.gl.materials.properties.uniforms.UniformM4;
import furusystems.display.gl.materials.properties.VertAttribute;
import nme.geom.Matrix3D;
import nme.gl.GL;
import nme.gl.GLProgram;
import nme.gl.GLUniformLocation;
import nme.gl.GLUtils;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */

enum ParamType {
	FLOAT;
	FLOAT_MAT2;
	FLOAT_MAT3;
	FLOAT_MAT4;
	FLOAT_VEC2;
	FLOAT_VEC3;
	FLOAT_VEC4;
	INT;
	INT_VEC2;
	INT_VEC3;
	INT_VEC4;
}

class GLSLShader
{
	public var program:GLProgram;
	public var attributes:Map<String, VertAttribute>;
	public var uniforms:Map<String, Uniform>;
	
	public function new(vsSource:String, fsSource:String) 
	{
		trace("New shader");
		attributes = new Map<String, VertAttribute>();
		uniforms = new Map<String, Uniform>();
		
		program = GLUtils.createProgram(vsSource, fsSource);
		
		var va = GL.getProgramParameter(program, GL.ACTIVE_ATTRIBUTES);
		trace("Attributes");
		for (i in 0...va) {			
			var a = GL.getActiveAttrib(program, i);
			trace("\t" + a.name);
			attributes.set(a.name, createAttribute(a.name, GL.getAttribLocation(program, a.name), a.size, a.type));
		}
		var nu = GL.getProgramParameter(program, GL.ACTIVE_UNIFORMS);
		trace("Uniforms");
		for (i in 0...nu) {
			var u = GL.getActiveUniform(program, i);
			trace("\t" + u.name);
			uniforms.set(u.name, createUniform(u.name, GL.getUniformLocation(program, u.name), u.size, u.type));
			
		}
	}
	
	public static function createAttribute(name:String, index:Int, size:Int, type:Int):VertAttribute {
		return new VertAttribute(name, getParamType(type), index, size);
	}
	
	public function getUniform(name:String):Uniform {
		return uniforms.get(name);
	}
	
	public function getUniformLocation(name:String):Int {
		if (!uniforms.exists(name)) {
			trace("No uniform: " + name);
			return -1;
		}
		return uniforms.get(name).position;
	}
	
	public function setUniform(name:String, value:Dynamic):Void {
		if (!uniforms.exists(name)) return;
		uniforms.get(name).value = value;
	}
	
	public function updateUniforms():Void {
		for (u in uniforms) 
		{
			u.update();
		}
	}
	
	public static function getParamType(type:Int):ParamType {
		switch(type) {
			case GL.FLOAT:
				return ParamType.FLOAT;
			case GL.FLOAT_MAT2:
				return ParamType.FLOAT_MAT2;
			case GL.FLOAT_MAT3:
				return ParamType.FLOAT_MAT3;
			case GL.FLOAT_MAT4:
				return ParamType.FLOAT_MAT4;
			case GL.FLOAT_VEC2:
				return ParamType.FLOAT_VEC2;
			case GL.FLOAT_VEC3:
				return ParamType.FLOAT_VEC3;
			case GL.FLOAT_VEC4:
				return ParamType.FLOAT_VEC4;
			case GL.INT:
				return ParamType.INT;
			case GL.INT_VEC2:
				return ParamType.INT_VEC2;
			case GL.INT_VEC3:
				return ParamType.INT_VEC3;
			case GL.INT_VEC4:
				return ParamType.INT_VEC4;
			default:
				return ParamType.FLOAT;
		}
	}
	public static function createUniform(name:String, index:GLUniformLocation, size:Int, type:Int):Uniform {
		switch(getParamType(type)) {
			case ParamType.INT:
				return new UniformI(name, size, index);
			case ParamType.INT_VEC2:
				return new UniformI2(name, size, index);
			case ParamType.INT_VEC3:
				return new UniformI3(name, size, index);
			case ParamType.INT_VEC4:
				return new UniformI4(name, size, index);
			case ParamType.FLOAT:
				return new UniformF(name, size, index);
			case ParamType.FLOAT_VEC2:
				return new UniformF2(name, size, index);
			case ParamType.FLOAT_VEC3:
				return new UniformF3(name, size, index);
			case ParamType.FLOAT_VEC4:
				return new UniformF4(name, size, index);
			case ParamType.FLOAT_MAT2:
				return new UniformM2(name, size, index);
			case ParamType.FLOAT_MAT3:
				return new UniformM3(name, size, index);
			case ParamType.FLOAT_MAT4:
				return new UniformM4(name, size, index);
		}
	}
	
}