

class DebugGfx
{
   public function new() { }

   public function lineTo(x:Float,y:Float)
   {
      neko.Lib.println("gfx.lineTo(" + x + "," + y + ");");
   }
   public function moveTo(x:Float,y:Float)
   {
      neko.Lib.println("gfx.moveTo(" + x + "," + y + ");");
   }
   public function endFill()
   {
      neko.Lib.println("gfx.endFill();");
   }
   public function beginFill(inColour:Int,inAlpha:Float)
   {
      neko.Lib.println("gfx.beginFill(" + inColour +"," + inAlpha + ");");
   }
   public function lineStyle(thickness:Float,
                             ?color:Null<Int> /* = 0 */,
                             ?alpha:Null<Float> /* = 1.0 */,
                             ?pixelHinting:Null<Bool> /* = false */,
                             ?scaleMode:Null<String> /* = "normal" */,
                             ?caps:Null<String>,
                             ?joints:Null<String>,
                             ?miterLimit:Null<Float> /*= 3*/)
   {
      neko.Lib.println("lineStyle...");
   }
   public function beginGradientFill(type : nme.GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 ?matrix : nme.Matrix,
                 ?spreadMethod : Null<nme.SpreadMethod>,
                 ?interpolationMethod : Null<nme.InterpolationMethod>,
                 ?focalPointRatio : Null<Float>) : Void
   {
      neko.Lib.println("beginGradientFill...");
   }



}


class Main
{
   public static function main() { (new Main()).Run(); }

   function new()
   {
   }

   function Run()
   {
      var args = neko.Sys.args();
      if (args.length!=1)
      {
         neko.Lib.println("Usage : SVG2Gfx file.svg");
         return;
      }

      var xml_data = neko.io.File.getContent(args[0]);
      if (xml_data.length < 1)
      {
         neko.Lib.println("SVG2Gfx, bad file:" + args[0]);
         return;
      }

      var xml = Xml.parse(xml_data);


      // neko.Lib.println("Read:" + xml);

      var svg2gfx = new SVG2Gfx(xml);

      var debugger = new DebugGfx();

      svg2gfx.Render(debugger,new nme.Matrix(),1.0,1.0);
   }



}
