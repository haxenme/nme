package furusystems.display.gl.materials.properties.uniforms;
import com.furusystems.games.tower.utils.IntPoint;
import nme.geom.Point;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformI2 extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:IntPoint) 
	{
		super(name, size, index);
		if (defaultValue == null) defaultValue = new IntPoint();
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniform2i(position, value.x, value.y);
	}
	
}