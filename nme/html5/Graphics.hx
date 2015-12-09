package nme.html5;
import js.Browser;
import js.html.Element;
import js.html.svg.SVGElement;
import js.html.svg.RectElement;

class Graphics
{
   private var svgNs = "http://www.w3.org/2000/svg";  

   var svg:SVGElement;
   var fill:String;

   public function new(inSvg:SVGElement)
   {
      svg = inSvg;
      // TODO - get this right
      svg.setAttribute("width","400");
      svg.setAttribute("height","400");
   }

   public function beginFill(inColour:Int, inAlpha:Float)
   {
      fill = "#" + StringTools.hex(inColour,6);
   }

   public function drawRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
   {
      var rect:RectElement = cast Browser.document.createElementNS(svgNs,"rect"); 
      rect.setAttribute('x', untyped inX );
      rect.setAttribute('y', untyped inY );
      rect.setAttribute('width', untyped inWidth );
      rect.setAttribute('height', untyped inHeight );
      rect.setAttribute('fill', fill);
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



