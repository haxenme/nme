package nme.preloader;
import js.html.*;

class HtmlPreloader
{
   static var context:CanvasRenderingContext2D;
   static var canvas:CanvasElement;

   public static function render(count:Int, of:Int)
   {
      if (count==of)
      {
         var doc  = js.Browser.window.document;
         doc.body.removeChild(canvas);
         canvas = null;
         context = null;
         untyped js.Browser.window.preloadUpdate = null;
      }
      else
      {
         var w = canvas.width;
         var h = canvas.height;
         var ctx = context;
         ctx.fillStyle = "#b0b0b0";
         ctx.fillRect(0,0,w,h);
         ctx.strokeStyle = "#000060";
         ctx.lineWidth = 1;
         ctx.beginPath();
         ctx.rect(w*0.2, h/2-30,w*0.6, 60);
         ctx.stroke();
         ctx.fillStyle = "#000060";
         ctx.fillRect(w*0.22, h/2-28,w*0.56*(count+1)/(of+1), 56);
      }
   }

   public static function main()
   {
      var doc  = js.Browser.window.document;
      canvas = cast doc.createElement("canvas");
      canvas.width = js.Browser.window.innerWidth;
      canvas.height = js.Browser.window.innerHeight;
      doc.body.appendChild(canvas);
      context = canvas.getContext2d();
      render(0,10);
      untyped js.Browser.window.preloadUpdate = render;
   }
}
