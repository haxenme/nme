package nme.format.swf;

import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.display.JointStyle;

import nme.display.Graphics;
import nme.format.swf.SWFStream;
import nme.format.SWF;

typedef RenderFunc = Graphics -> Void;
typedef RenderFuncList = Array<RenderFunc>;

class ShapeEdge
{
   public function new() {}

   public function connects(next:ShapeEdge)
   {
       return fillStyle==next.fillStyle && Math.abs(x1-next.x0)<0.00001 &&
                                           Math.abs(y1-next.y0)<0.00001;
   }
   public function asCommand()
   {
      //trace("lineTo(" + x1 + "," + y1 + ")");
      if (isQuadratic)
         return function(gfx:Graphics) gfx.curveTo(cx,cy,x1,y1);
      else
         return function(gfx:Graphics) gfx.lineTo(x1,y1);
   }
   public function dump()
   {
      trace(x0 + "," + y0 + " -> " + x1 + "," + y1 + " (" + fillStyle + ")" );
   }


   public static function line(style:Int, x0:Float, y0:Float, x1:Float, y1:Float)
   {
      var result = new ShapeEdge();
      result.fillStyle = style;
      result.x0 = x0;
      result.y0 = y0;
      result.x1 = x1;
      result.y1 = y1;
      result.isQuadratic = false;
      return result;
   }
   public static function curve(style:Int, x0:Float, y0:Float, cx:Float, cy:Float, x1:Float, y1:Float)
   {
      var result = new ShapeEdge();
      result.fillStyle = style;
      result.x0 = x0;
      result.y0 = y0;
      result.cx = cx;
      result.cy = cy;
      result.x1 = x1;
      result.y1 = y1;
      result.isQuadratic = true;
      return result;
   }

   public var fillStyle:Int;
   public var x0:Float;
   public var y0:Float;
   public var x1:Float;
   public var y1:Float;
   public var isQuadratic:Bool;
   public var cx:Float;
   public var cy:Float;
}

class Shape
{
   var mBounds:Rectangle;
   var mEdgeBounds:Rectangle;
   var mHasNonScaled:Bool;
   var mHasScaled:Bool;
   var mCommands:RenderFuncList;
   var mFillStyles:RenderFuncList;
   var mSWF:SWF;
   var mWaitingLoader:Bool;

   static var ftSolid  = 0x00;
   static var ftLinear = 0x10;
   static var ftRadial = 0x12;
   static var ftRadialF= 0x13;
   static var ftBitmapRepeatSmooth  = 0x40;
   static var ftBitmapClippedSmooth = 0x41;
   static var ftBitmapRepeat        = 0x42;
   static var ftBitmapClipped       = 0x43;


   public function new(inSWF:SWF, inStream:SWFStream, inVersion:Int)
   {
      mSWF = inSWF;

      inStream.AlignBits();
      mCommands = [];
      mBounds = inStream.ReadRect();
      mWaitingLoader = false;
      // trace(mBounds);

      if (inVersion==4)
      {
         inStream.AlignBits();
         mEdgeBounds = inStream.ReadRect();
         inStream.AlignBits();
         inStream.Bits(6);
         mHasNonScaled = inStream.ReadBool();
         mHasScaled = inStream.ReadBool();
      }
      else
      {
         mEdgeBounds = mBounds.clone();
         mHasScaled = mHasNonScaled = true;
      }

      mFillStyles = ReadFillStyles(inStream,inVersion);
      var line_styles = ReadLineStyles(inStream,inVersion);

      inStream.AlignBits();
      var fill_bits = inStream.Bits(4);
      var line_bits = inStream.Bits(4);


      //trace("fill_bits " + fill_bits);
      //trace("line_bits " + line_bits);

      var pen_x = 0.0;
      var pen_y = 0.0;

      var current_fill0 = -1;
      var current_fill1 = -1;

      var current_line = -1;
      var edges = new RenderFuncList();
      var fills = new Array<ShapeEdge>();

      while(true)
      {
         var edge = inStream.ReadBool();
         // trace("Edge :" + edge);
         if (!edge)
         {
            var new_styles = inStream.ReadBool();
            var new_line_style = inStream.ReadBool();
            var new_fill_style1 = inStream.ReadBool();
            var new_fill_style0 = inStream.ReadBool();
            var move_to = inStream.ReadBool();

             //trace("new_styles : " + new_styles);
             //trace("new_line_style : " + new_line_style);
             //trace("new_fill_style0 : " + new_fill_style0);
             //trace("new_fill_style1 : " + new_fill_style1);
             //trace("move_to : " + move_to);
   
            // End-of-shape - Done !
            if (!move_to && !new_styles && !new_line_style && 
                    !new_fill_style1 && !new_fill_style0 )
            {
               break;
            }
 
            if (inVersion!=2 && inVersion!=3)
            {
               // The case where new_styles==true seems to have some
               //  additional data (bitmap?) for embeded line styles.
               new_styles = false;
            }


            // Style changed record ...
            if (move_to)
            {
               var bits = inStream.Bits(5);
               var px = inStream.Twips(bits);
               var py = inStream.Twips(bits);
               //trace("Move : " + px + "," + py + "(" + current_fill0 + "," + current_fill1 + ")" );
               edges.push( function(g:Graphics) { g.moveTo(px,py);} );
               pen_x = px;
               pen_y = py;
            }
   
            if (new_fill_style0)
            {
               current_fill0 = inStream.Bits(fill_bits);
               //trace(" fill0 : " + current_fill0);
            }

            if (new_fill_style1)
            {
               current_fill1 = inStream.Bits(fill_bits);
               //trace(" fill1 : " + current_fill1);
            }
   
            if (new_line_style)
            {
               var line_style = inStream.Bits(line_bits);
               if (line_style>=line_styles.length)
                   throw("Invalid line style: " + line_style + "/" +
                       line_styles.length + " (" + line_bits + ")");
               var func =  line_styles[line_style];
               edges.push(func);
               current_line = line_style;
               //trace("Line style " + current_line);
            }
 
            // Hmmm - do this, or just flush fills?
            if (new_styles)
            {
               FlushCommands(edges,fills);
               if (edges.length>0)
                  edges = [];
               if (fills.length>0)
                  fills = [];

               inStream.AlignBits();
               mFillStyles = ReadFillStyles(inStream,inVersion);
               line_styles = ReadLineStyles(inStream,inVersion);
               fill_bits = inStream.Bits(4);
               line_bits = inStream.Bits(4);
               current_line = -1;
               current_fill0 = -1;
               current_fill1 = -1;
            }

           //trace("fill_bits : " + fill_bits);
            //trace("line_bits : " + line_bits);
         }
         // edge ..
         else
         {
            // straight
            if (inStream.ReadBool())
            {
               var px = pen_x;
               var py = pen_y;

               var delta_bits = inStream.Bits(4) + 2;
               if (inStream.ReadBool())
               {
                  px += inStream.Twips(delta_bits);
                  py += inStream.Twips(delta_bits);
               }
               else if (inStream.ReadBool())
                  py += inStream.Twips(delta_bits);
               else
                  px += inStream.Twips(delta_bits);
   
               if (current_line>0)
                  edges.push( function(g:Graphics) { g.lineTo(px,py);} );
               else
                  edges.push( function(g:Graphics) { g.moveTo(px,py);} );

               //trace("Line to : " + px + "," + py  + " (" + current_fill0 + "," + current_fill1 + ")" );
               if (current_fill0>0)
                 fills.push(ShapeEdge.line(current_fill0,pen_x,pen_y,px,py));

               if (current_fill1>0)
                 fills.push(ShapeEdge.line(current_fill1,px,py,pen_x,pen_y));

               pen_x = px;
               pen_y = py;
            }
            // Curved ...
            else
            {
               var delta_bits = inStream.Bits(4) + 2;
               var cx = pen_x + inStream.Twips(delta_bits);
               var cy = pen_y + inStream.Twips(delta_bits);
               var px = cx + inStream.Twips(delta_bits);
               var py = cy + inStream.Twips(delta_bits);
               // Can't push "pen_x/y" in closure because it uses a reference
               //  to the member variable, not a copy of the current value.

               //trace("Curve to : " + px + "," + py  + " (" + current_fill0 + "," + current_fill1 + ")" );
               if (current_line>0)
                  edges.push( function(g:Graphics) { g.curveTo(cx,cy,px,py);} );
               if (current_fill0>0)
                 fills.push(ShapeEdge.curve(current_fill0,pen_x,pen_y,cx,cy,px,py));
               if (current_fill1>0)
                 fills.push(ShapeEdge.curve(current_fill1,px,py,cx,cy,pen_x,pen_y));
 
               pen_x = px;
               pen_y = py;
            }
         }
      }
      FlushCommands(edges,fills);

      mSWF = null;

      // Render( new nme.display.DebugGfx());
   }

   function FlushCommands(edges:RenderFuncList, fills:Array<ShapeEdge>)
   {
      var left = fills.length;
      while(left>0)
      {
         var first = fills[0];
         fills[0] = fills[--left];
         if (first.fillStyle>=mFillStyles.length)
            throw("Invalid fill style");
         //if (first.connects(first))
           //continue;
         //trace("Loop start : " + first.x0 + "," + first.y0);
         //trace("Fill style: " + first.fillStyle);
         mCommands.push(mFillStyles[first.fillStyle]);
         var mx = first.x0;
         var my = first.y0;
         //trace("moveTo(" + mx + "," + my + ")");
         mCommands.push(function(gfx:Graphics) gfx.moveTo(mx,my));
         mCommands.push(first.asCommand());
         var prev = first;
         var loop = false;
         while(!loop)
         {
            //trace("seeking " + prev.x1 + "," + prev.y1 + "   " + prev.fillStyle);
            var found = false;
            for(i in 0...left)
            {
               //trace(" check " + fills[i].x0 + "," + fills[i].y0 + "   " + fills[i].fillStyle);
               if (prev.connects(fills[i]))
               {
                  prev = fills[i];
                  fills[i] = fills[--left];
                  mCommands.push(prev.asCommand());
                  found = true;
                  if (prev.connects(first))
                     loop = true;
                  break;
               }
            }
            if (!found)
            {
               trace("Remaining:");
               for(f in 0...left)
                  fills[f].dump();
              throw("Dangling fill : " + prev.x1 + "," + prev.y1 + "  " + prev.fillStyle);
              break;
            }
         }
      }
      if (fills.length>0)
         mCommands.push( function(gfx:Graphics) gfx.endFill() );
      mCommands = mCommands.concat(edges);
      if (edges.length>0)
         mCommands.push(function(gfx:Graphics) gfx.lineStyle() );
   }

   public function Render(inGraphics:Graphics)
   {
      mWaitingLoader = false;
      for(c in mCommands)
         c(inGraphics);
      return mWaitingLoader;
   }


   function ReadFillStyles(inStream:SWFStream,inVersion:Int) : RenderFuncList
   {
      var result:RenderFuncList = [];

      // Special null fill-style
      result.push( function(g:Graphics) { g.endFill(); } );

      var n = inStream.ReadArraySize(true);
      for(i in 0...n)
      {
         var fill = inStream.ReadByte();
         if (fill==ftSolid)
         {
            var RGB = inStream.ReadRGB();
            // trace("FILL " + i + " = " + RGB );
            var A = inVersion >= 3 ? (inStream.ReadByte()/255.0) : 1.0;
            result.push( function(g:Graphics) { g.beginFill(RGB,A); } );
         }
         // Gradient
         else if (fill==ftLinear || fill==ftRadial || fill==ftRadialF )
         {
            var matrix = inStream.ReadMatrix();
            inStream.AlignBits();
            var spread = inStream.ReadSpreadMethod();
            var interp = inStream.ReadInterpolationMethod();
            var n = inStream.Bits(4);
            var colors = [];
            var alphas = [];
            var ratios = [];
            for(i in 0...n)
            {
               ratios.push( inStream.ReadByte() );
               colors.push( inStream.ReadRGB() );
               alphas.push( inVersion>=3 ? inStream.ReadByte()/255.0 : 1.0 );
            }
            var focus = fill==ftRadialF ?  inStream.ReadByte()/255.0 : 0.0;
            var type = fill==ftLinear ? flash.display.GradientType.LINEAR :
                                         flash.display.GradientType.RADIAL;

            result.push( function(g:Graphics) {
               g.beginGradientFill(type,colors,alphas,ratios,matrix,
                                   spread, interp, focus ); } );
                                   
         }
         // Bitmap
         else if (fill==ftBitmapRepeatSmooth || fill==ftBitmapClippedSmooth ||
                  fill==ftBitmapRepeat || fill==ftBitmapClipped )
         {
            inStream.AlignBits();
            var id = inStream.ReadID();
            // trace("Bitmap Fill : 0x" + StringTools.hex(fill) + "  " + id);

            var matrix = inStream.ReadMatrix();
            // Not too sure about these.
            // A scale of (20,20) is 1 pixel-per-unit.
            matrix.a *= 0.05;
            matrix.b *= 0.05;
            matrix.c *= 0.05;
            matrix.d *= 0.05;
            //trace("mtx : " + matrix.a + " " + matrix.c + " " + matrix.tx );
            //trace("      " + matrix.b + " " + matrix.d + " " + matrix.ty );

            inStream.AlignBits();
            var repeat = fill == ftBitmapRepeat || fill==ftBitmapRepeatSmooth;
            var smooth = fill == ftBitmapRepeatSmooth||
                         fill ==ftBitmapClippedSmooth;

            var bitmap = mSWF.getBitmapDataID(id);
            if (bitmap!=null)
            {
               result.push( function(g:Graphics) {
                  g.beginBitmapFill(bitmap,matrix,repeat,smooth); } );
            }
            // May take some time for bitmap to load ...
            else
            {
               var s = mSWF;
               var me = this;
               result.push( function(g:Graphics) {
                  if (bitmap==null)
                  {
                     bitmap = s.getBitmapDataID(id);
                     if (bitmap==null)
                     {
                        me.mWaitingLoader = true;
                        g.endFill();
                        return;
                     }
                     else
                        me = null;
                  }

               g.beginBitmapFill(bitmap,matrix,repeat,smooth); } );
            }
         }
         else
         {
            throw("Unknown fill style : 0x" + StringTools.hex(fill) );
         }
      }
      return result;
   }

   function ReadLineStyles(inStream:SWFStream,inVersion:Int) : RenderFuncList
   {
      var result:RenderFuncList = [];

      // Special null line-style
      result.push( function(g:Graphics) { g.lineStyle(); } );

      var n = inStream.ReadArraySize(true);
       
      for(i in 0...n)
      {
         // Linestyle 2
         if (inVersion>=4)
         {
            inStream.AlignBits();
            var w = inStream.ReadDepth()*0.05;
            var start_caps = inStream.ReadCapsStyle();
            var joints = inStream.ReadJoinStyle();
            var has_fill = inStream.ReadBool();
            var scale = inStream.ReadScaleMode();
            var pixel_hint = inStream.ReadBool();
            var reserved = inStream.Bits(5);
            var no_close = inStream.ReadBool();
            var end_caps = inStream.ReadCapsStyle();
            var miter = joints==JointStyle.MITER ? inStream.ReadDepth()/256.0:1;
            var color = has_fill ? 0 : inStream.ReadRGB();
            var A = has_fill  ? 1.0 : (inStream.ReadByte()/255.0);

            /*
             trace("Width  :" + w);
             trace("Startcaps  :" + start_caps);
             trace("Joints  :" + joints);
             trace("HasFill  :" + has_fill);
             trace("scale  :" + scale);
             trace("pixel_hint  :" + pixel_hint);
             trace("reserved  :" + reserved);
             trace("no_close  :" + no_close);
             trace("end_caps  :" + end_caps);
             trace("miter  :" + miter);
             trace("Colour :" + color);
             trace("Alpha  :" + A);
            */
            if (has_fill)
            {
               var fill = inStream.ReadByte();

               // Gradient
               if ( (fill & 0x10) !=0 )
               {
                  var matrix = inStream.ReadMatrix();
                  inStream.AlignBits();
                  var spread = inStream.ReadSpreadMethod();
                  var interp = inStream.ReadInterpolationMethod();
                  var n = inStream.Bits(4);
                  var colors = [];
                  var alphas = [];
                  var ratios = [];
                  for(i in 0...n)
                  {
                     ratios.push( inStream.ReadByte() );
                     colors.push( inStream.ReadRGB() );
                     alphas.push( inStream.ReadByte()/255.0 );
                  }
                  var focus = fill==ftRadialF ?  inStream.ReadByte()/255.0 : 0.0;
                  var type = fill==ftLinear ? flash.display.GradientType.LINEAR :
                                               flash.display.GradientType.RADIAL;
      
                  result.push( function(g:Graphics) {
                     g.lineStyle(w,0,1,pixel_hint,scale,start_caps,joints,miter);
                     g.lineGradientStyle(type,colors,alphas,ratios,matrix,
                                         spread, interp, focus ); } );
                                         
               }
               else
                  throw("Unknown fillStyle");

            }
            else
            {
               result.push( function(g:Graphics)
                 { g.lineStyle(w,color,A,pixel_hint,scale,start_caps,joints,miter); } );
            }
         }
         else
         {
            inStream.AlignBits();
            var w = inStream.ReadDepth()*0.05;
            var RGB = inStream.ReadRGB();
            var A = inVersion >= 3 ? (inStream.ReadByte()/255.0) : 1.0;
            result.push( function(g:Graphics) { g.lineStyle(w,RGB,A); } );
         }
      }

      return result;
   }

}
