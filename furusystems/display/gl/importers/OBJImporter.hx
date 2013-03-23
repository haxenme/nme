package furusystems.display.gl.importers;
import furusystems.display.gl.mesh.Mesh;
import nme.Assets;
import nme.errors.Error;
import nme.geom.Point;
import nme.geom.Vector3D;

/**
 * ...
 * @author Andreas Rønning
 */
typedef Vert = { x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, u:Float, v:Float, index:Int};
typedef Tex = { u:Float, v:Float };
typedef Face = { a:Vert, b:Vert, c:Vert };
typedef Normal = { x:Float, y:Float, z:Float };
class OBJImporter
{
	public static var cache:Map<String,Mesh> = new Map<String,Mesh>();
	private static inline var v:String = "v";
	private static inline var vt:String = "vt";
	private static inline var f:String = "f";
	private static inline var vn:String = "vn";
	private static var verts:Array<Vert>;
	private static var texes:Array<Tex>;
	private static var faces:Array<Face>;
	private static var normals:Array<Normal>;
	private static var vertMap:Map<String,Vert>;
	private static var verts2:Array<Vert>;
	public static function create(path:String):Mesh {
		if (cache.exists(path)) {
			return cache.get(path);
		}
		var data:String = Assets.getText(path);
		var out:Mesh = new Mesh(path);
		var lines:Array<String> = data.split("\n");
		verts = new Array<Vert>();
		verts2 = new Array<Vert>();
		texes = new Array<Tex>();
		normals = new Array<Normal>();
		faces = new Array<Face>();
		vertMap = new Map<String,Vert>();
		for (i in 0...lines.length) {
			processLine(lines[i]);
		}
		var outVertices:Array<Vertex> = new Array<Vertex>();
		for (v in verts2) {
			outVertices.push(
				Mesh.createVertex(
					new Vector3D(v.x, v.y, v.z),
					new Vector3D(v.nx, v.ny, v.nz), 
					new Vector3D(), 
					new Point(v.u, v.v), 
					new Vector3D(1, 1, 1, 1)
					)
				);
		}
		var outIndices:Array<Int> = new Array<Int>();
		for (f in faces) {
			outIndices.push(f.a.index);
			outIndices.push(f.b.index);
			outIndices.push(f.c.index);
			
		}
		
		out.createVertexBuffer(outVertices, false);
		out.createIndexBuffer(outIndices);
		
		verts = null;
		texes = null;
		faces = null;
		normals = null;
		vertMap = null;
		cache.set(path, out);
		return out;
	}
	public static function clearCache():Void {
		for (v in cache.iterator()) {
			v.dispose();
		}
		cache = new Map<String,Mesh>();
	}
	private inline static function processLine(l:String):Void {
		var tokens:Array<String> = l.split(" ");
		switch(tokens.shift()) {
			case v:
				addVert(tokens);
			case vt:
				addTex(tokens);
			case f:
				addFace(tokens);
			case vn:
				addNormal(tokens);
		}
	}
	private inline static function addNormal(tokens:Array<String>):Void {
		normals.push( { x:Std.parseFloat(tokens[0]), y:Std.parseFloat(tokens[1]), z:Std.parseFloat(tokens[2])} );
	}
	private inline static function addVert(tokens:Array<String>):Void {
		var p:Int = verts.length;
		verts.push( { x:Std.parseFloat(tokens[0]), y:Std.parseFloat(tokens[1]), z:Std.parseFloat(tokens[2]), nx:0, ny:0, nz:0, u:0, v:0, index:p } );
	}
	private inline static function addTex(tokens:Array<String>):Void {
		texes.push( { u:Std.parseFloat(tokens[0]), v:Std.parseFloat(tokens[1])} );
	}
	private inline static function addFace(tokens:Array<String>):Void {
		var face:Face = { a:null, b:null, c:null };
		if (tokens.length != 3) throw new Error("Mesh must be triangulated");
		face.a = evalVert(tokens[0]);
		face.b = evalVert(tokens[1]);
		face.c = evalVert(tokens[2]);
		
		faces.push(face);
	}
	
	private static inline function evalVert(tokens:String):Vert {
		if (!vertMap.exists(tokens)) {
			var split:Array<String> = tokens.split("/");
			var v1:Vert = getVert(split[0]);
			var t1:Tex = getTex(split[1]);
			var n1:Normal = getNormal(split[2]);
			var v2:Vert = { x:v1.x, y:v1.y, z:v1.z, nx:n1.x, ny:n1.y, nz:n1.z, u:t1.u, v:t1.v, index:verts2.length };
			verts2.push(v2);
			vertMap.set(tokens, v2);
		}
		return vertMap.get(tokens);
	}
	
	private static inline function getVert(index:String):Vert {
		return verts[Std.parseInt(index)-1];
	}
	private static inline function getTex(index:String):Tex {
		return texes[Std.parseInt(index)-1];
	}
	private static inline function getNormal(index:String):Normal {
		return normals[Std.parseInt(index)-1];
	}
	
}