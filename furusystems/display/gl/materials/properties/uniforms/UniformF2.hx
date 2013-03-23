package furusystems.display.gl.materials.properties.uniforms;
import nme.geom.Point;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformF2 extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:Point) 
	{
		super(name, size, index);
		if (defaultValue == null) defaultValue = new Point();
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniform2f(position, value.x, value.y);
	}
	
}