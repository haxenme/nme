package furusystems.display.gl.materials.properties.uniforms;
import nme.geom.Vector3D;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformF3 extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:Vector3D) 
	{
		super(name, size, index);
		if (defaultValue == null) defaultValue = new Vector3D();
		value = defaultValue;
	}
	
	override public function update():Void 
	{
		GL.uniform3f(position, value.x, value.y, value.z);
	}
	
}