package nme.display;

class Graphics
{
   var nmeHandle:Dynamic;

   public function new(inHandle:Dynamic)
   {
      nmeHandle = inHandle;
   }

   public function beginFill(color:Int, alpha:Float = 1.0)
   {
      nme_gfx_begin_fill(nmeHandle,color,alpha);
   }

   public function endFill()
   {
      nme_gfx_end_fill(nmeHandle);
   }

   public function clear()
   {
      nme_gfx_clear(nmeHandle);
   }

   public function lineStyle(?thickness:Null<Float>, color:Int = 0, alpha:Float = 1.0,
                      pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle,
                      ?joints:JointStyle, miterLimit:Float = 3) : Void
   {
      nme_gfx_line_style(nmeHandle, thickness, color, alpha, pixelHinting,
         scaleMode==null ?  0 : Type.enumIndex(scaleMode),
         caps==null ?  0 : Type.enumIndex(caps),
         joints==null ?  0 : Type.enumIndex(joints),
         miterLimit );
   }



   public function moveTo(inX:Float, inY:Float)
   {
      nme_gfx_move_to(nmeHandle,inX,inY);
   }

   public function lineTo(inX:Float, inY:Float)
   {
      nme_gfx_line_to(nmeHandle,inX,inY);
   }

   public function curveTo(inCX:Float, inCY:Float, inX:Float, inY:Float)
   {
      nme_gfx_curve_to(nmeHandle,inCX,inCY,inX,inY);
   }

   public function arcTo(inCX:Float, inCY:Float, inX:Float, inY:Float)
   {
      nme_gfx_arc_to(nmeHandle,inCX,inCY,inX,inY);
   }

   public function drawEllipse(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
   {
      nme_gfx_draw_ellipse(nmeHandle,inX,inY,inWidth,inHeight);
   }

   public function drawCircle(inX:Float, inY:Float, inRadius:Float)
   {
      nme_gfx_draw_ellipse(nmeHandle,inX,inY,inRadius,inRadius);
   }

   public function drawGraphicsData(graphicsData:Array<IGraphicsData>):Void
	{
		var handles = new Array<Dynamic>();
		for(datum in graphicsData)
			handles.push(datum.nmeHandle);
		nme_gfx_draw_data(nmeHandle,handles);
	}

   public function drawGraphicsDatum(graphicsDatum:IGraphicsData):Void
	{
		nme_gfx_draw_datum(nmeHandle,graphicsDatum.nmeHandle);
	}


   static var nme_gfx_clear = nme.Loader.load("nme_gfx_clear",1);
   static var nme_gfx_begin_fill = nme.Loader.load("nme_gfx_begin_fill",3);
   static var nme_gfx_end_fill = nme.Loader.load("nme_gfx_end_fill",1);
   static var nme_gfx_line_style = nme.Loader.load("nme_gfx_line_style",-1);

   static var nme_gfx_move_to = nme.Loader.load("nme_gfx_move_to",3);
   static var nme_gfx_line_to = nme.Loader.load("nme_gfx_line_to",3);
   static var nme_gfx_curve_to = nme.Loader.load("nme_gfx_curve_to",5);
   static var nme_gfx_arc_to = nme.Loader.load("nme_gfx_arc_to",5);
   static var nme_gfx_draw_ellipse = nme.Loader.load("nme_gfx_draw_ellipse",5);
   static var nme_gfx_draw_data = nme.Loader.load("nme_gfx_draw_data",2);
   static var nme_gfx_draw_datum = nme.Loader.load("nme_gfx_draw_datum",2);
}
