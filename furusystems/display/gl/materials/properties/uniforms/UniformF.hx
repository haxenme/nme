package furusystems.display.gl.materials.properties.uniforms;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformF extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, defaultValue:Float = 0) 
	{
		super(name, size, index);
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniform1f(position, value);
	}
	
}