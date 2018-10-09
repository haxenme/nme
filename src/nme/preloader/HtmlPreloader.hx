package nme.preloader;
import js.html.*;

class HtmlPreloader
{
   static var context:CanvasRenderingContext2D;
   static var canvas:CanvasElement;
   static var restoreCanvas:Void->Void;
   static var bg:String;
   static var fg:String;

   public static function close()
   {
      var win  = js.Browser.window;
      var doc  = win.document;
      restoreCanvas();
      canvas = null;
      context = null;
      untyped win.preloadUpdate = null;
      untyped win.closeProgress = null;
   }

   public static function render(fraction:Float)
   {
      var win  = js.Browser.window;
      var w = canvas.width;
      var h = canvas.height;
      var ctx = context;
      //var scale = win.devicePixelRatio;
      //if (scale==null) scale = 1;
      var scale = 1;
      var bw = Std.int(w - scale*20);
      if (bw<20) bw = w;
      var bh = Std.int(scale*20);

      ctx.fillStyle = bg;
      ctx.fillRect(0,0,w,h);
      ctx.strokeStyle = fg;
      ctx.lineWidth = 1;
      ctx.beginPath();
      var border = Std.int(scale*2);
      ctx.rect(Std.int((w-bw)/2)-border, Std.int((h-bh)/2)-border, bw+border*2, bh+border*2);
      ctx.stroke();
      ctx.fillStyle = fg;
      ctx.fillRect(Std.int((w-bw)/2), Std.int((h-bh)/2), bw*fraction, bh);
   }

   public static function main()
   {
      var win  = js.Browser.window;
      bg = untyped win.preloadBg;
      if (bg==null) bg = "#b0b0b0";
      fg = untyped win.preloadFg;
      if (fg==null) fg = "#000060";

      var doc  = win.document;
      canvas = doc.createCanvasElement();
      canvas.width = win.innerWidth;
      canvas.height = win.innerHeight;
      canvas.className = "preloader";

      var parent:Node = cast doc.getElementById("stage");
      if (parent!=null)
      {
         var oldCanvas = doc.getElementById("canvas");
         if (oldCanvas!=null)
         {
            var oldDisplay = oldCanvas.style.display;
            oldCanvas.style.display = "None";
            restoreCanvas = function() {
                oldCanvas.style.display = oldDisplay;
                parent.removeChild(canvas);
            }
         }
      }
      else
         parent = doc.body;

      parent.appendChild(canvas);
      if (restoreCanvas==null)
         restoreCanvas = function() parent.removeChild(canvas);

      context = canvas.getContext2d();
      render(0);
      untyped win.preloadUpdate = render;
      untyped win.closePreloader = close;
   }
}
