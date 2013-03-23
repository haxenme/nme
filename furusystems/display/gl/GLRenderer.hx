package furusystems.display.gl;
import furusystems.display.gl.camera.Camera;
import furusystems.display.gl.materials.Material;
import furusystems.display.gl.mesh.Mesh;
import furusystems.display.gl.mesh.primitives.Quad;
import furusystems.display.gl.objects.Transform3D;
import furusystems.display.gl.objects.WorldObject;
import nme.display.BitmapData;
import nme.display.OpenGLView;
import nme.events.Event;
import nme.geom.Matrix3D;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.geom.Vector3D;
import nme.gl.GL;
import nme.gl.GLFramebuffer;
import nme.gl.GLProgram;
import nme.gl.GLRenderbuffer;
import nme.gl.GLTexture;
import nme.utils.ArrayBuffer;
import nme.utils.UInt8Array;
import nme.Vector;

/**
 * ...
 * @author Andreas Rønning
 */

typedef Batch = { verts:Array<Vertex>, indices:Array<Int> };
class GLRenderer extends OpenGLView
{
	private var program:GLProgram;
	
	public var camera:Camera;
	
	public var rootTransform:Transform3D;
	
	private var materialMap:Map<String, Array<WorldObject>>;
	private var materialList:Array<Material> ;
	private var meshList:Array<Mesh> ;
	private var objectList:Array<WorldObject>;
	
	private var currentMesh:Mesh = null;
	private var depthMaterial:Material;
	
	private var fbo:GLFramebuffer;
	private var depthBuffer:GLRenderbuffer;
	
	private var fxaa:Material;
	
	private var screenQuad:Quad;
	private var fullscreenTexture:GLTexture;
	
	public var backbufferSize:Point;
	
	public var clearColor:Vector3D;
	
	public var preRender:Void->Void = null;
	
	public function new() 
	{
		super();
		clearColor = new Vector3D(0,0,0,0);
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}
   
	private function getPixelArray(bmd:BitmapData):UInt8Array {
		var ints:Vector<Int> = bmd.getVector(bmd.rect); 
		var l:Int = bmd.height * bmd.width;
		var pixels = new UInt8Array(new ArrayBuffer(ints.length * 4));
		var offset:Int = 0;
		for (i in ints) {
			var a:Int = i >> 24;
			var r:Int = i >> 16 & 0xFF;
			var g:Int = i >>  8 & 0xFF;
			var b:Int = i & 0xFF;
			pixels[offset] = r;
			pixels[offset+1] = g;
			pixels[offset+2] = b;
			pixels[offset + 3] = a;
			offset += 4;
		}
		return pixels;
	}
	
	public function reset():Void {
		
	}
	
	private function initFXAA():Void {
		
		screenQuad = new Quad();
		fxaa = new Material("FXAA", "shaders/FullscreenQuad.vs", "shaders/FXAA.fs");
		
		fbo = GL.createFramebuffer();
		depthBuffer = GL.createRenderbuffer();
		
		fullscreenTexture = GL.createTexture();
		GL.bindTexture(GL.TEXTURE_2D, fullscreenTexture);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR); 
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);		
		GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGB, Std.int(backbufferSize.x), Std.int(backbufferSize.y), 0, GL.RGB, GL.UNSIGNED_BYTE, null);
		GL.bindTexture(GL.TEXTURE_2D, null);
		
		GL.bindRenderbuffer(GL.RENDERBUFFER, depthBuffer);
		GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT, Std.int(backbufferSize.x), Std.int(backbufferSize.y));
		
		GL.bindFramebuffer(GL.FRAMEBUFFER, fbo);
		GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, fullscreenTexture, 0);
		GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, depthBuffer);
		
		trace("Checking fbo status");
		var status = GL.checkFramebufferStatus(GL.FRAMEBUFFER);
		switch (status) {
			case GL.FRAMEBUFFER_COMPLETE:
				trace("Framebuffer okay");
			case GL.FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
				throw("Incomplete framebuffer: FRAMEBUFFER_INCOMPLETE_ATTACHMENT");
			case GL.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
				throw("Incomplete framebuffer: FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT");
			case GL.FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
				throw("Incomplete framebuffer: FRAMEBUFFER_INCOMPLETE_DIMENSIONS");
			case GL.FRAMEBUFFER_UNSUPPORTED:
				throw("Incomplete framebuffer: FRAMEBUFFER_UNSUPPORTED");
			default:
				trace("Incomplete framebuffer: " + status);
		}
		
		GL.bindFramebuffer(GL.FRAMEBUFFER, null);
		GL.bindRenderbuffer(GL.RENDERBUFFER, null);
	}

	private function onAddedToStage(e:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		stage.addEventListener(Event.RESIZE, onStageResize);
		rootTransform = new Transform3D();
		
		backbufferSize = new Point(stage.stageWidth, stage.stageHeight);
		
		meshList = [];
		materialList = [];
		objectList = [];
		materialMap = new Map<String, Array<WorldObject>>();
		
		#if (!iphone && earlyZ)
		depthMaterial = new Material("DepthPass", "shaders/DepthPass.vs", "shaders/DepthPass.fs");
		#end
		

		
		
		camera = new Camera();
		camera.width = stage.stageWidth;
		camera.height = stage.stageHeight;
		//
		
		/*
		var size = 20;
		var b:Bool = true;
		var n = 500;
		var prevPt:Vector3D = null;
		for (i in 0...n) 
		{
			var t:Float = i / (n - 1);
			var scaleMod:Float = Math.sin(t * 4 * 6.28);
			scaleMod += 1;
			scaleMod *= 0.5;
			
			var p:Vector3D = l(t);
			p.scaleBy(size);
			
			//var p:Vector3D = new Vector3D(MathStuff.randNorm()*s,MathStuff.randNorm()*s,MathStuff.randNorm()*s);
			//var r:Vector3D = new Vector3D(MathStuff.randNorm() * 360, MathStuff.randNorm() * 360, MathStuff.randNorm() * 360);
			var r:Vector3D = lookAt(p, new Vector3D(0, 0, 0));
			r.z = t * 360;
			
			
			//var scale:Float = Math.random() + 0.1;
			var scale:Float = 2+scaleMod*0.5;
			var s:Vector3D = new Vector3D(scale, scale, scale);
			var wo:WorldObject = new TestObject(i / n * 6.28*8);
			//wo.mesh = meshList[Math.floor(Math.random() * meshList.length)];
			wo.mesh = meshList[1];
			b = !b;
			
			wo.material = materialList[0];
			materialMap.get(wo.material.name).push(wo);
			if(n!=1){
				wo.position = p;
				wo.rotation = r;
				wo.scale = s;
			}
			objectList.push(wo);
			rootTransform.addChild(wo);
			
			prevPt = p;
		}
		*/
		
		sortObjects();
		
		GL.enable(GL.DITHER);
		GL.enable(GL.SAMPLE_ALPHA_TO_COVERAGE);
		GL.frontFace(GL.CCW);
		GL.enable(GL.BLEND);
		
		
		GL.colorMask(true, true, true, true);
		GL.clearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
		GL.clearDepth(1);
		
		#if fxaa
		initFXAA();
		#else
		GL.enable(GL.CULL_FACE);
		GL.enable(GL.DEPTH_TEST);
		#end
	}
	
	public function sortObjects() 
	{
		for (mat in materialList) {
			sortByMesh(materialMap.get(mat.name));
			sortByMesh(objectList);
		}
	}
	
	public function addMaterial(m:Material):Material {
		if (m == null) return m;
		if (materialMap.exists(m.name)) return m;
		trace("Added new material: " + m.name);
		materialMap.set(m.name, new Array<WorldObject>());
		materialList.push(m);
		return m;
	}
	
	public function addMesh(m:Mesh):Mesh {
		if (m == null) return m;
		for (m2 in meshList) {
			if (m2 == m) return m;
		}
		trace("Added new mesh: " + m.name);
		meshList.push(m);
		return m;
	}
	
	public function addChild(wo:WorldObject):WorldObject {
		rootTransform.addChild(wo);
		addMaterial(wo.material);
		addMesh(wo.mesh);
		if (wo.material != null) {
			materialMap.get(wo.material.name).push(wo);
		}
		objectList.push(wo);
		return wo;
	}
	public function removeChild(wo:WorldObject):WorldObject {
		rootTransform.removeChild(wo);
		return wo;
	}
	
	public static function lookAt(from:Vector3D, to:Vector3D, asAngles:Bool = true):Vector3D {
		var out:Vector3D = new Vector3D();
		var diff:Vector3D = to.subtract(from);
		var xzdistance:Float = Math.sqrt(diff.x * diff.x + diff.z * diff.z);
		if(asAngles){
			out.y = Math.atan2(diff.x, diff.z) * 180 / Math.PI;
			out.x = -Math.atan2(diff.y, xzdistance) * 180 / Math.PI;
		}else {
			out.y = Math.atan2(diff.x, diff.z);
			out.x = -Math.atan2(diff.y, xzdistance);
		}
		out.z = 0;
		return out;
	}
	
	private function onStageResize(e:Event):Void 
	{
		camera.width = stage.stageWidth;
		camera.height = stage.stageHeight;
		backbufferSize.x = stage.stageWidth;
		backbufferSize.y = stage.stageHeight;
		#if fxaa
		refreshFXAA();
		#end
	}
	
	private function refreshFXAA() 
	{
		GL.bindTexture(GL.TEXTURE_2D, fullscreenTexture);
		GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, Std.int(backbufferSize.x), Std.int(backbufferSize.y), 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
		GL.bindTexture(GL.TEXTURE_2D, null);
		
		GL.bindRenderbuffer(GL.RENDERBUFFER, depthBuffer);
		GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT, Std.int(backbufferSize.x), Std.int(backbufferSize.y));
		GL.bindRenderbuffer(GL.RENDERBUFFER, null);
		
		GL.bindFramebuffer(GL.FRAMEBUFFER, fbo);
		GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, fullscreenTexture, 0);
		GL.bindFramebuffer(GL.FRAMEBUFFER, null);
	}
	
	
	override public function render(rect:Rectangle):Void 
	{
		if (preRender != null) preRender();
		
        var w = rect.width;
        var h = rect.height;
		
		camera.update();
		rootTransform.update();
		rootTransform.predraw(); //build matrices
		camera.worldViewInverse.copyFrom(camera.matrix);
		camera.worldViewInverse.append(rootTransform.matrix);

		#if fxaa
		//Draw to texture...
		GL.bindFramebuffer(GL.FRAMEBUFFER, fbo);
		GL.bindRenderbuffer(GL.RENDERBUFFER, depthBuffer);
		#end
		
		GL.viewport(Std.int(0), Std.int(0), Std.int(backbufferSize.x), Std.int(backbufferSize.y));
		GL.clearDepth(1);
		GL.clearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
		GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
		
		//PRIMARY RENDER
		#if fxaa
		GL.enable(GL.CULL_FACE);
		GL.enable(GL.DEPTH_TEST);
		#end
		
		GL.depthFunc(GL.LESS);
		GL.depthMask(true);
		
		#if (!iphone && earlyZ)
		GL.colorMask(false, false, false, false);
		depthMaterial.predraw(camera.camProj);
		drawObjects(objectList, depthMaterial);
		depthMaterial.postdraw();
		GL.depthFunc(GL.LEQUAL);
		GL.depthMask(false);
		GL.colorMask(true, true, true, true);
		#end
		
		
		for (m in materialList) 
		{
			drawMaterial(m);
		}
		
		currentMesh = null;
		
		//AA
		#if fxaa
		GL.bindFramebuffer(GL.FRAMEBUFFER, null);
		GL.bindRenderbuffer(GL.RENDERBUFFER, null);
		
        GL.viewport(Std.int(0), Std.int(0), Std.int(backbufferSize.x), Std.int(backbufferSize.y));
		GL.clearDepth(1);
		GL.clearColor(0, 0, 0, 0);
		GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
		
		GL.depthMask(true);
		GL.disable(GL.CULL_FACE);
		GL.disable(GL.DEPTH_TEST);
		
		fxaa.predraw(camera);
		GL.activeTexture(GL.TEXTURE0);
		GL.bindTexture(GL.TEXTURE_2D, fullscreenTexture);
		GL.uniform1i(fxaa.shader.getUniformLocation("textureSampler"), 0);
		GL.uniform2f(fxaa.shader.getUniformLocation("texcoordOffset"),1/backbufferSize.x, 1/backbufferSize.y);
		screenQuad.predraw();
		fxaa.apply(screenQuad);
		GL.drawElements(GL.TRIANGLES, screenQuad.indexCount, GL.UNSIGNED_BYTE, 0);
		screenQuad.postdraw();
		GL.bindTexture(GL.TEXTURE_2D, null);
		//}
		#end
		
	}
	private inline function drawMaterial(m:Material):Void {
		var l = materialMap.get(m.name);
		if (l.length > 0){
			m.predraw(camera);
			drawObjects(l, m);
			m.postdraw();
		}
	}
	private inline function drawObjects(objects:Array<WorldObject>, material:Material):Void {
		var count = 0;
		for (o in objects) {
			if (!o.visible || o.mesh == null) continue;
			if (o.mesh != currentMesh) {
				if (currentMesh != null) currentMesh.postdraw();
				currentMesh = o.mesh;
				currentMesh.predraw();
				material.apply(currentMesh);
			}
			o.prerender();
			GL.drawElements(material.renderMode, currentMesh.indexCount, GL.UNSIGNED_BYTE, 0);
			count++;
		}
		if (currentMesh != null) {
			currentMesh.postdraw();
			currentMesh = null;
		}
	}
	
	private inline function sortByMesh(list:Array<WorldObject>):Void {
		list.sort(meshSortFunc);
	}
	private function meshSortFunc(a:WorldObject, b:WorldObject):Int {
		if (a.mesh.uid == b.mesh.uid) return -1;
		return 1;
	}
	public function dispose():Void {
		for (m in meshList) {
			m.dispose();
		}
		for (m in materialList) {
			m.dispose();
		}
		#if fxaa
		GL.deleteFramebuffer(fbo);
		GL.deleteRenderbuffer(depthBuffer);
		fxaa.dispose();
		#end
	}
	
}