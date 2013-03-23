package furusystems.display.gl.materials.properties.uniforms;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformI extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, defaultValue:Int = 0) 
	{
		super(name, size, index);
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniform1i(position, value);
	}
	
}