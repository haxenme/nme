#if !flash
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.display.BitmapData;
import nme.display.Graphics;
import nme.display.TriangleCulling;
import nme.Lib;
#else
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.TriangleCulling;
import flash.Lib;
#end



class Sample extends Sprite 
{
   var t0:Float;

   public function new()
   {
      super();
      Lib.current.addChild(this);

      #if !flash
		onLoaded(BitmapData.load("../03-Bitmaps/Image.jpg"));
		#else
       var loader = new flash.display.Loader();
       var me = this;
       loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,
          function(e:flash.events.Event)
             {
             var obj:flash.display.Bitmap = untyped loader.content;
             me.onLoaded(obj.bitmapData);
             }
          );
       loader.load(new flash.net.URLRequest("../03-Bitmaps/Image.jpg"));
		#end
   }

	function onLoaded(inData:BitmapData)
	{
      var me = this;
      t0 = haxe.Timer.stamp();
      stage.addEventListener( Event.ENTER_FRAME, function(_) { me.doUpdate(inData); } );
	}

	function doUpdate(inData:BitmapData)
	{
		var gfx = graphics;
      gfx.clear();
		gfx.beginBitmapFill(inData);
		gfx.lineStyle(4,0x0000ff);

		var sx = 1.0/inData.width;
		var sy = 1.0/inData.height;

      var theta = (haxe.Timer.stamp()-t0);
      var cos = Math.cos(theta);
      var sin = Math.cos(theta);
      var z = sin*100;
      var w0 = 150.0/(200.0+z);
      var w1 = 150.0/(200.0-z);

      var x0 = 200;
      var y0 = 200;
		var vertices = [
		  x0 + 100*cos*w0,  y0  -100*w0,
		  x0 + 100*cos*w0,  y0  +100*w0,
		  x0 - 100*cos*w1,  y0  +100*w1,
		  x0 - 100*cos*w1,  y0  -100*w1];

		var indices = [
		   0, 1, 2,
			2, 3, 0 ];

		var tex_uv = [
		  100.0*sx, 000.0*sy,
		  100.0*sx, 200.0*sy,
		  300.0*sx, 200.0*sy,
		  300.0*sx, 000.0*sy  ];

		var tex_uvt = [
		  100.0*sx, 000.0*sy, w0,
		  100.0*sx, 200.0*sy, w0,
		  300.0*sx, 200.0*sy, w1,
		  300.0*sx, 000.0*sy, w1  ];

      drawTriangles(gfx, vertices, indices, tex_uvt );
   }

   function drawTriangles(inGfx:Graphics, ?verts:Array<Float>, ?indices:Array<Int>,
                    ?tex:Array<Float>, ?cull:TriangleCulling )
   {
      #if flash
      var verts_v = new flash.Vector<Float>(verts.length);
      for(i in 0...verts.length) verts_v[i] = verts[i];
      var indices_v = new flash.Vector<Int>(indices.length);
      for(i in 0...indices.length) indices_v[i] = indices[i];
      var tex_v = new flash.Vector<Float>(tex.length);
      for(i in 0...tex.length) tex_v[i] = tex[i];

      inGfx.drawTriangles(verts_v, indices_v, tex_v, cull);
      #else
      inGfx.drawTriangles(verts, indices, tex, cull);
      #end

   }

   private function onEnterFrame( event: Event ): Void
   {
   }

public static function main()
{
#if !flash
   nme.Lib.create(function(){new Sample();},550,400,60,0xffeeee,
        (0*nme.Lib.HARDWARE) | nme.Lib.RESIZABLE);
#else
   new Sample();
#end
}


}

