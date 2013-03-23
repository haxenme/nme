package furusystems.display.gl.materials.properties.uniforms;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Float32Array;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformM2 extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:Array<Float>) 
	{
		super(name, size, index);
		if (defaultValue == null) defaultValue = [0, 0, 0, 0];
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniformMatrix2fv(position, false, new Float32Array(value));
	}
}