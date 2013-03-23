package furusystems.display.gl.materials.properties.uniforms;
import com.furusystems.games.tower.utils.IntVec4;
import nme.gl.GL;
import nme.gl.GLUniformLocation;

/**
 * ...
 * @author Andreas Rønning
 */
class UniformI4 extends UniformI3
{
	public function new(name:String, size:Int, index:GLUniformLocation, ?defaultValue:IntVec4) 
	{
		super(name, size, index, defaultValue);
	}
	override public function update():Void 
	{
		GL.uniform4i(position, value.x, value.y, value.z, value.w);
	}
	
}