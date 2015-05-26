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
         backgroundColor = 0x00FFFFFF;

      var shape = new Shape();
      var renderer = new SvgRenderer(svg);
      var matrix = new Matrix();
      var scale = Math.max( width/svg.width, height/svg.height );
      matrix.a = matrix.d = scale;
      matrix.tx = (width-svg.width*scale)*0.5;
      matrix.ty = (height-svg.height*scale)*0.5;
      renderer.render(shape.graphics, matrix,null,null,width,height);

      var bitmapData = new BitmapData(width, height, true, backgroundColor);
      bitmapData.draw(shape);

      return bitmapData;
   }

   public static function resizeBitmapData(bitmapData:BitmapData, width:Int, height:Int):BitmapData 
   {
      var bitmap = new Bitmap(bitmapData);
      var backgroundColor = 0x00FFFFFF;

      bitmap.smoothing = true;

      var matrix = new Matrix();
      // Show central portion, or pad with alpha?
      var scale = Math.max( width/bitmapData.width, height/bitmapData.height );
      //var scale = Math.min( width/bitmapData.width, height/bitmapData.height );
      matrix.a = scale;
      matrix.d = scale;
      matrix.tx = Std.int( (width - scale*bitmap.width)*0.5 );
      matrix.ty = Std.int( (height - scale*bitmap.height)*0.5 );

      var data = new BitmapData(width, height, true, backgroundColor);
      data.draw(bitmap,matrix);

      return data;
   }
}
