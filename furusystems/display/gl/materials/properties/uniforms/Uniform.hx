package furusystems.display.gl.materials.properties.uniforms;
import nme.errors.Error;
import nme.gl.GLUniformLocation;

/**
 * ...
 * @author Andreas Rønning
 */
class Uniform
{

	public var name:String;
	public var size:Int;
	public var position:GLUniformLocation;
	public var dirty:Bool;
	public var value:Dynamic;
	public function new(name:String, size:Int, position:GLUniformLocation) 
	{
		this.name = name;
		this.size = size;
		this.position = position;
	}
	public function update():Void {
		throw new Error("Abstract uniform cannot update");
	}
	
}