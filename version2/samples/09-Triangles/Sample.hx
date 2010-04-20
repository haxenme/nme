import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.display.BitmapData;



class Sample extends Sprite 
{
   public function new()
   {
      super();
      nme.Lib.current.addChild(this);

		var data = BitmapData.load("../03-Bitmaps/Image.jpg");

		var gfx = graphics;
		gfx.beginBitmapFill(data);

		var sx = 1.0/data.width;
		var sy = 1.0/data.height;

		var vertices = [
		  100.0, 100.0,
		  100.0, 300.0,
		  300.0, 300.0,
		  300.0, 100.0 ];

		var indices = [
		   0, 1, 2,
			2, 3, 0 ];

		var tex_uv = [
		  100.0*sx, 100.0*sy,
		  100.0*sx, 300.0*sy,
		  300.0*sx, 300.0*sy,
		  300.0*sx, 100.0*sy ];

      gfx.drawTriangles(vertices, indices, tex_uv);

      //addEventListener( Event.ENTER_FRAME, onEnterFrame );
   }

   private function onEnterFrame( event: Event ): Void
   {
   }

public static function main()
{
   nme.Lib.create(function(){new Sample();},550,400,60,0x202040,
        (1*nme.Lib.HARDWARE) | nme.Lib.RESIZABLE);
}


}

