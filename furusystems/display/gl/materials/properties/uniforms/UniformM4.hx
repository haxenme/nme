package furusystems.display.gl.materials.properties.uniforms;
import nme.geom.Matrix3D;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformM4 extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:Matrix3D) 
	{
		super(name, size, index);
		if (defaultValue == null) defaultValue = new Matrix3D();
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniformMatrix3D(position, false, value);
	}
	
}