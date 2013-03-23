package furusystems.display.gl.mesh.primitives;
import furusystems.display.gl.mesh.Mesh;
import nme.geom.Point;
import nme.geom.Vector3D;
import nme.gl.GL;

/**
 * ...
 * @author Andreas Rønning
 */
class Quad extends Mesh
{

	public function new() 
	{
		super();
		
		createVertexBuffer([
			Mesh.createVertex(new Vector3D(-1, 1, 0), new Vector3D(0, 0, 1), new Vector3D(0, 0, 1), new Point(0, 0), new Vector3D(1, 0, 0, 1)),
			Mesh.createVertex(new Vector3D(1, 1, 0), new Vector3D(0, 0, 1), new Vector3D(0, 0, 1), new Point(1, 0), new Vector3D(0, 1, 0, 1)),
			Mesh.createVertex(new Vector3D(1, -1, 0), new Vector3D(0, 0, 1), new Vector3D(0, 0, 1), new Point(1, 1), new Vector3D(0, 0, 1, 1)),
			Mesh.createVertex(new Vector3D(-1, -1, 0), new Vector3D(0, 0, 1), new Vector3D(0, 0, 1), new Point(0, 1), new Vector3D(1, 1, 0, 1))
		]);
		
		createIndexBuffer([
			0, 1, 2, 0, 2, 3
		]);
		name = "Quad";
	}
	
}