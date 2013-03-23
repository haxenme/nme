package furusystems.display.gl.mesh;
import nme.geom.Point;
import nme.geom.Vector3D;
import nme.gl.GL;
import nme.gl.GLBuffer;
import nme.utils.ByteArray;
import nme.utils.Float32Array;

/**
 * ...
 * @author Andreas Rønning
 */

 
typedef Color = { r:Float, g:Float, b:Float, a:Float };
typedef Float3 = { x:Float, y:Float, z:Float };
typedef Float2 = { x:Float, y:Float };
typedef Vertex = { pos:Float3, norm:Float3, binorm:Float3, uv:Float2, rgba:Color };

class Mesh
{
	
	public static inline var VERT_STRIDE:Int = 60;
	public var vbo:GLBuffer;
	public var ibo:GLBuffer;
	
	public var isBound:Bool = false;
	
	public var verts:Array<Vertex>;
	public var indices:Array<Int>;
	
	public var name:String = "Mesh";
	
	public var posLocation:Int;
	public var uvLocation:Int;
	public var colorLocation:Int;
	
	public var vertexCount:Int;
	public var indexCount:Int;
	
	public var uid:Int;
	private static var uidPool:Int = 0;
	public function new(name:String = "Mesh") 
	{
		this.name = name;
		uid = uidPool++;
		vbo = ibo = null;
		verts = null;
	}
	
	public function createVertexBuffer(verts:Array<Vertex>, computeNormals:Bool = true):GLBuffer {
		if (vbo != null) GL.deleteBuffer(vbo);
		this.verts = verts;
		vertexCount = verts.length;
		vbo = GL.createBuffer();
		GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
		GL.bufferData(GL.ARRAY_BUFFER, createVertexArray(verts, computeNormals), GL.STATIC_DRAW);
		return vbo;
	}
	
	public function predraw():Void {
		if (isBound) return; //Avoid repeat binds?
		isBound = true;
		GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
		GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, ibo);
	}
	public function postdraw():Void {
		if (!isBound) return;
		isBound = false;
	}
	
	private inline function createVertexArray(verts:Array<Vertex>, computeNormals:Bool = false):Float32Array {
		if (computeNormals) computeVertexNormals(verts);
		var out:Array<Float> = [];
		var offset:Int = 0;
		for (v in verts) {
			out[offset] = v.pos.x;
			out[offset + 1] = v.pos.y;
			out[offset + 2] = v.pos.z;
			out[offset + 3] = v.norm.x;
			out[offset + 4] = v.norm.y;
			out[offset + 5] = v.norm.z;
			out[offset + 6] = v.binorm.x;
			out[offset + 7] = v.binorm.y;
			out[offset + 8] = v.binorm.z;
			out[offset + 9] = v.uv.x;
			out[offset + 10] = v.uv.y;
			out[offset + 11] = v.rgba.r;
			out[offset + 12] = v.rgba.g;
			out[offset + 13] = v.rgba.b;
			out[offset + 14] = v.rgba.a;
			offset += 15;
		}
		return new Float32Array(out);
	}
	
	public function createIndexBuffer(indices:Array<Int>):GLBuffer {
		this.indices = indices;
		if (ibo != null) GL.deleteBuffer(ibo);
		ibo = GL.createBuffer();
		
		GL.bindBuffer(GL.ARRAY_BUFFER, ibo);
		GL.bufferData(GL.ARRAY_BUFFER, createIndexBytes(indices), GL.STATIC_DRAW);
		indexCount = indices.length;
		
		return ibo;
	}
	private inline function createIndexBytes(indices:Array<Int>):ByteArray {
		var out = new ByteArray();
		for (i in indices) {
			out.writeByte(i);
		}
		return out;
	}
	
	public function enable():Void {
		
	}
	
	public function allocate():Void {
		createVertexBuffer(verts);
	}
	public function dispose():Void {
		if (vbo != null) GL.deleteBuffer(vbo);
		if (ibo != null) GL.deleteBuffer(ibo);
	}
	
	public static inline function createVertex(pos:Vector3D, norm:Vector3D, binorm:Vector3D, uv:Point, color:Vector3D):Vertex {
		return { pos: { x:pos.x, y:pos.y, z:pos.z }, norm: { x:norm.x, y:norm.y, z:norm.z }, binorm: { x:binorm.x, y:binorm.y, z:binorm.z }, uv: { x:uv.x, y:uv.y }, rgba: { r:color.x, g:color.y, b:color.z, a:color.w }};
	}
	
	public function computeVertexNormals(verts:Array<Vertex>, strength:Float = 0):Void {
		//simple stupid
		for (v in verts) {
			computeVertexNormal(v);
		}
	}
	private inline function computeVertexNormal(vert:Vertex, hard:Bool = true):Void {
		var pos:Float3 = vert.pos;
		var norm:Float3 = vert.norm;
		if(!hard){
			norm.x = pos.x;
			norm.y = pos.y;
			norm.z = pos.z;
		}else {
			norm.x = norm.y = 0;
			norm.z = pos.z;
		}
		normalize(norm);
	}
	public static inline function normalize(f:Float3):Void {
		var length:Float = Math.sqrt(f.x * f.x + f.y * f.y + f.z * f.z);
		f.x /= length;
		f.y /= length;
		f.z /= length;
	}
	
}