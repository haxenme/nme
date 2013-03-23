package furusystems.display.gl.materials.properties.uniforms;
import com.furusystems.games.tower.utils.IntPoint;
import com.furusystems.games.tower.utils.IntVec4;
import nme.gl.GL;
import nme.gl.GLUniformLocation;
import nme.utils.Property;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformI3 extends Uniform
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:IntVec4) 
	{
		super(name, size, index);
		if (defaultValue == null) defaultValue = new IntVec4();
		value = defaultValue;
	}
	override public function update():Void 
	{
		GL.uniform3i(position, value.x, value.y, value.z);
	}
	
}