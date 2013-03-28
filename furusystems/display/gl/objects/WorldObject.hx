package furusystems.display.gl.objects;
import furusystems.display.gl.materials.Material;
import furusystems.display.gl.mesh.Mesh;
import nme.geom.Matrix3D;
import nme.gl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
typedef MaterialOverride = { location:Int, name:String, value:Dynamic };
class WorldObject extends Transform3D
{

	public var mesh:Mesh;
	public var material:Material;
	public var visible:Bool;
	public var materialOverrides:Map<String,MaterialOverride>;
	public function new() 
	{
		super();
		visible = true;
		mesh = null;
		material = null;
	}
	override public function prerender():Void {
		pushOverrides();
	}
	
	private inline function pushOverrides():Void 
	{
		
	}
	
	
}