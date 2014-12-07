import gm2d.svg.Svg;
import gm2d.svg.SvgRenderer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.geom.Rectangle;
import nme.geom.Matrix;

class ImageHelper 
{
   public static function rasterizeSVG(svg:Svg, width:Int, height:Int, backgroundColor:Int = null):BitmapData 
   {
      if (backgroundColor == null) 
      {
         backgroundColor = #if (!neko ||(haxe3 && !neko_v1)) 0x00FFFFFF #else { rgb: 0xFFFFFF, a: 0x00 } #end;
      }

      var shape = new Shape();
      var renderer = new SvgRenderer(svg);
      var matrix = new Matrix();
      var scale = Math.min( width/svg.width, height/svg.height );
      matrix.a = matrix.d = scale;
      renderer.render(shape.graphics, matrix,null,null,width,height);

      var bitmapData = new BitmapData(width, height, true, backgroundColor);
      bitmapData.draw(shape);

      return bitmapData;
   }

   public static function resizeBitmapData(bitmapData:BitmapData, width:Int, height:Int):BitmapData 
   {
      var bitmap = new Bitmap(bitmapData);

      bitmap.smoothing = true;
      bitmap.width = width;
      bitmap.height = height;

      var data = new BitmapData(width, height, true, #if (!neko ||(haxe3 && !neko_v1)) 0x00FFFFFF #else { rgb: 0xFFFFFF, a: 0x00 } #end);
      data.draw(bitmap);

      return data;
   }
}
