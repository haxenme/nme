package nme;

typedef DrawList = Array<Void>;

class LinePoint
{
   public var x:Float;
   public var y:Float;
   public var thickness:Float;
   public var colour:Int;
   public var alpha:Float;

   public function new(inX,inY,inThick,inCol,inAlpha)
   {
     x = inX;
     y = inY;
     thickness = inThick;
     colour = inCol;
     alpha = inAlpha;
   }
   public function DifferentPos(inRHS:LinePoint)
     { return x!=inRHS.x || y!=inRHS.y; }
}

typedef LineSegments = Array<LinePoint>;

class Graphics
{
   private var mPenX:Float;
   private var mPenY:Float;
   private var mDrawList:DrawList;
   private var mFilling:Bool;
   private var mLines:LineSegments;
   private var mSurface:Void;

   var mThickness:Float;
   var mColour:Int;
   var mAlpha:Float;

   var mFillColour:Int;
   var mFillAlpha:Float;

   public function new(?inSurface:Void)
   {
      mPenX = 0;
      mPenY = 0;
      mThickness = 1.0;
      mColour = 0;
      mFillColour = 0;
      mAlpha = 1.0;
      mFillAlpha = 1.0;
      mSurface = inSurface;

      mDrawList = new DrawList();
      mLines = new LineSegments();
      mFilling = false;
   }

   public function Render()
   {
      CloseList(true);
      for(obj in mDrawList)
         nme_draw_object(obj);
   }

   public function render(?inMatrix:Matrix,?inSurface:Void)
   {
      var dest:Void = inSurface == null ? Manager.getScreen() : inSurface;
      CloseList(true);
      for(obj in mDrawList)
         nme_draw_object_to(obj,dest,inMatrix);
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
      mThickness = thickness;
      mColour = color==null ? 0 : color;
      mAlpha = alpha==null ? 1.0 : alpha;
   }

   public function beginFill(color:Null<Int>, ?alpha:Null<Float>)
   {
      CloseList(true);
      mFillColour = color;
      mFillAlpha = alpha==null ? 1.0 : alpha;
      mFilling=true;
   }

   public function endFill()
   {
      CloseList(true);
   }

   // TODO: could me more efficient to leave this up to implementation
   public function drawCircle(x:Float,y:Float,rad:Float)
   {
      CloseList(false);

      var steps = Math.round(rad*6);
      if (steps>4)
      {
         var theta = 0.0;
         var d_theta = Math.PI * 2.0 / steps;
         moveTo( x+rad, y );
         for(s in 1...steps)
         {
            theta += d_theta;
            lineTo( x+rad*Math.cos(theta), y + rad*Math.sin(theta) );
         }
         lineTo( x+rad, y );
      }

      CloseList(false);
   }

   public function drawRect(x:Float,y:Float,width:Float,height:Float)
   {
      CloseList(false);

      moveTo(x,y);
      lineTo(x+width,y);
      lineTo(x+width,y+height);
      lineTo(x,y+height);
      lineTo(x,y);

      CloseList(false);
   }

   public function beginGradientFill(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 ?matrix : Matrix,
                 ?spreadMethod : SpreadMethod,
                 ?interpolationMethod : InterpolationMethod,
                 ?focalPointRatio : Float) : Void
   {
      // TODO:
      beginFill(0xff0000,1.0);
   }



   public function clear()
   {
      mDrawList = new DrawList();
      if (mLines.length!=0)
         mLines = new LineSegments();
      mFilling = false;
   }

   public function moveTo(inX:Float,inY:Float)
   {
      if (mLines.length>0) CloseList(false);
      mPenX = inX;
      mPenY = inY;
   }

   public function lineTo(inX:Float,inY:Float)
   {
      if (mLines.length==0)
         mLines.push( new LinePoint(mPenX,mPenY,mThickness,mColour,mAlpha) );

      mPenX = inX;
      mPenY = inY;
      mLines.push( new LinePoint(mPenX,mPenY,mThickness,mColour,mAlpha) );
   }

   public function curveTo(inX:Float,inY:Float,inX1:Float,inY1:Float)
   {
      // TODO:
      lineTo(inX,inY);
   }

   public function flush() { CloseList(true); }

   private function AddDrawable(inDrawable:Void)
   {
      if (mSurface==null)
         // Store for 'ron ...
         mDrawList.push( inDrawable );
      else
      {
         nme_draw_object_to(inDrawable,mSurface,null);
      }
   }

   private function CloseList(inCancelFill)
   {
      var l =  mLines.length;
      if (l!=0)
      {
         if (mFilling && mLines[0].DifferentPos(mLines[l-1]))
            mLines.push( new LinePoint(mLines[0].x,mLines[0].y,
                                       mThickness,mColour,mAlpha) );
         
         var alpha:Float = mFilling ? mFillAlpha : 0.0;
         AddDrawable( nme_create_draw_obj(mFillColour, alpha,
                      untyped mLines.__neko() ) );

         mLines = new LineSegments();
      }

      if (inCancelFill)
         mFilling = false;
   }

   static var nme_draw_object = neko.Lib.load("nme","nme_draw_object",1);
   static var nme_draw_object_to = neko.Lib.load("nme","nme_draw_object_to",3);
   static var nme_create_draw_obj = neko.Lib.load("nme","nme_create_draw_obj",3);

}



