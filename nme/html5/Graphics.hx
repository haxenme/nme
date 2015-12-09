package nme.html5;
import js.Browser;
import js.html.Element;
import js.html.svg.SVGElement;
import js.html.svg.RectElement;

class Graphics
{
   private var svgNs = "http://www.w3.org/2000/svg";  

   var svg:SVGElement;
   var fillColour:Null<Int>;
   var fillAlpha:Float;

   public function new(inSvg:SVGElement)
   {
      svg = inSvg;
   }

   public function beginFill(inColour:Int, inAlpha:Float)
   {
      fillColour = inColour;
      fillAlpha = inAlpha;
   }

   public function drawRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
   {
      var rect:RectElement = cast Browser.document.createElementNS(svgNs,"rect"); 
      rect.setAttribute('x', Std.string(inX) );
      rect.setAttribute('y', Std.string(inY) );
      rect.setAttribute('width', Std.string(inWidth) );
      rect.setAttribute('height', Std.string(inHeight) );
      rect.setAttribute('fill', "#" + StringTools.hex(fillColour,6) );
      svg.appendChild(rect);
   }


   public static function nme_gfx_begin_fill(gfx:Graphics, colour:Int, alpha:Float)
   {
      gfx.beginFill(colour,alpha);
   }

   public static function nme_gfx_draw_rect(gfx:Graphics, inX:Float, inY:Float, inWidth:Float, inHeight:Float)
   {
      gfx.drawRect(inX, inY, inWidth, inHeight);
   }

}



