package nme.format.swf;

import nme.format.swf.SWFStream;
import nme.format.swf.SWF;
import nme.display.Graphics;

import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.display.JointStyle;
import nme.display.GradientType;


typedef MorphRenderFunc = Graphics -> Float -> Void;
typedef MorphRenderFuncList = Array<MorphRenderFunc>;

enum MorphEdge
{
   meStyle( func: Graphics -> Float -> Void );
   meMove(x:Float, y:Float);
   meLine(cx:Float, cy:Float, x:Float, y:Float);
   meCurve(cx:Float, cy:Float, x:Float, y:Float);
}

typedef MorphEdgeList = List<MorphEdge>;


class MorphShape
{
   var mBounds0:Rectangle;
   var mBounds1:Rectangle;
   var mEdgeBounds0:Rectangle;
   var mEdgeBounds1:Rectangle;
   var mHasNonScaled:Bool;
   var mHasScaled:Bool;
   var mCommands:MorphRenderFuncList;
   var mSWF:SWF;
   var mWaitingLoader:Bool;

   // TODO: make common with shape.hx
   static var ftSolid  = 0x00;
   static var ftLinear = 0x10;
   static var ftRadial = 0x12;
   static var ftRadialF= 0x13;
   static var ftBitmapRepeat  = 0x40;
   static var ftBitmapClipped = 0x41;
   static var ftBitmapRepeatR = 0x42;
   static var ftBitmapClippedR= 0x43;


   public function new(inSWF:SWF, inStream:SWFStream, inVersion:Int)
   {
      mSWF = inSWF;

      inStream.AlignBits();
      mCommands = [];
      mBounds0 = inStream.ReadRect();
      mBounds1 = inStream.ReadRect();
      mWaitingLoader = false;
      // trace(mBounds);


      if (inVersion==2)
      {
         inStream.AlignBits();
         mEdgeBounds0 = inStream.ReadRect();
         mEdgeBounds1 = inStream.ReadRect();
         inStream.AlignBits();
         inStream.Bits(6);
         mHasNonScaled = inStream.ReadBool();
         mHasScaled = inStream.ReadBool();
      }
      else
      {
         mEdgeBounds0 = mBounds0;
         mEdgeBounds1 = mBounds1;
         mHasScaled = mHasNonScaled = true;
      }

      inStream.AlignBits();
      var offset = inStream.ReadInt();
      var end_start = inStream.BytesLeft() - offset;

      var fill_styles = ReadFillStyles(inStream,inVersion);

      var line_styles = ReadLineStyles(inStream,inVersion);

      inStream.AlignBits();
      var fill_bits = inStream.Bits(4);
      var line_bits = inStream.Bits(4);


      //trace("fill_bits " + fill_bits);
      //trace("line_bits " + line_bits);


      var edges = new MorphEdgeList();
      var pen_x = 0.0;
      var pen_y = 0.0;

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

            // End-of-shape - Done !
            if (!move_to && !new_styles && !new_line_style && 
                    !new_fill_style1 && !new_fill_style0 )
               break;
 
            if (true)
            {
               // The case where new_styles==true seems to have some
               //  additional data (bitmap?) for embeded line styles.
               new_styles = false;
            }


            // Style changed record ...
            if (move_to)
            {
               var bits = inStream.Bits(5);
               pen_x = inStream.Twips(bits);
               pen_y = inStream.Twips(bits);
               edges.add( meMove(pen_x,pen_y) );
               //trace("Start: move " + pen_x + "," + pen_y );
            }
   
            if (new_fill_style0)
            {
               var fill_style = inStream.Bits(fill_bits);
               if (fill_style>=fill_styles.length)
                   throw("Invalid fill style");
               edges.add( meStyle(fill_styles[fill_style]) );
               //trace("Start: fill style");
            }
   
            if (new_fill_style1)
            {
               var fill_style = inStream.Bits(fill_bits);
               if (fill_style>=fill_styles.length)
                   throw("Invalid fill style");
           
               edges.add( meStyle(fill_styles[fill_style]) );
               //trace("Start: fill style");
            }
   
            if (new_line_style)
            {
               var line_style = inStream.Bits(line_bits);
               if (line_style>=line_styles.length)
                   throw("Invalid line style: " + line_style + "/" +
                       line_styles.length + " (" + line_bits + ")");
               edges.add(meStyle(line_styles[line_style]));
               //trace("Start: line style");
            }
         }
         // edge ..
         else
         {
            // straight
            if (inStream.ReadBool())
            {
               var delta_bits = inStream.Bits(4) + 2;
               var x0 = pen_x;
               var y0 = pen_y;
               if (inStream.ReadBool())
               {
                  pen_x += inStream.Twips(delta_bits);
                  pen_y += inStream.Twips(delta_bits);
               }
               else if (inStream.ReadBool())
                  pen_y += inStream.Twips(delta_bits);
               else
                  pen_x += inStream.Twips(delta_bits);
   
               edges.add( meLine((pen_x+x0)*0.5, (pen_y+y0)*0.5, pen_x,pen_y) );
               //trace("Start: lineTo " + pen_x + "," + pen_y);
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
               pen_x = px;
               pen_y = py;
               edges.add( meCurve(cx,cy,pen_x,pen_y) );
               //trace("Start: curveTo " + pen_x + "," + pen_y);
            }
         }
      }




      // Ok, now read the second half of the shape
      pen_x = 0.0;
      pen_y = 0.0;
      inStream.AlignBits();

      if ( end_start != inStream.BytesLeft())
         throw("end offset mismatch");

      fill_bits = inStream.Bits(4);
      line_bits = inStream.Bits(4);

      if (fill_bits!=0 || line_bits!=0)
         throw("unexpected style data in morph");

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

            if (new_line_style || new_fill_style0 || new_fill_style1 || new_styles)
               throw("Style change in Morph");

            // End-of-shape - Done !
            if (!move_to)
            {
               // trace("end edges done.");
               break;
            }
         }

         // Get start entry ...
         var x:Float=0;
         var y:Float=0;
         var cx:Float=0;
         var cy:Float=0;
         var is_move = false;
         var is_curve = false;
         var is_line = false;

         var edge_found = false;
         while( !edge_found )
         {
            var orig = edges.pop();
            if (orig==null)
               throw "Too few edges in first shape";
            edge_found = true;
            switch(orig)
            {
               case meMove(me_x,me_y):
                  x = me_x;
                  y = me_y;
                  is_move = true;
                  // trace("  pop move");
                  // here we have a "moveTo" in the first list and a "lineTo"
                  // in the second.  Combine these to a "move", and find the
                  // next line entry ...
                  //  ... or maybe just ignore it.
                  if (edge)
                  {
                     var px = pen_x;
                     var py = pen_y;
                     //mCommands.push( function(g:Graphics,f:Float)
                        //{ g.moveTo(x+(px-x)*f, y+(py-y)*f); } );
                     edge_found = false;
                  }

               case meLine(me_cx,me_cy,me_x,me_y):
                  cx = me_cx;
                  cy = me_cy;
                  x = me_x;
                  y = me_y;
                  is_line = true;
                  // trace("  pop line:" + x + "," + y);
               case meCurve(me_cx,me_cy,me_x,me_y):
                  cx = me_cx;
                  cy = me_cy;
                  x = me_x;
                  y = me_y;
                  is_curve = true;
                  // trace("  pop curve");
               case meStyle(func):
                  mCommands.push(func);
                  edge_found = false;
                  // trace("  pop style");
            }
         }

         // trace("Edge :" + edge);
         if (!edge)
         {
            if (!is_move)
               throw("MorphShape: mismatched move");


            var bits = inStream.Bits(5);
            pen_x = inStream.Twips(bits);
            pen_y = inStream.Twips(bits);
            var px = pen_x;
            var py = pen_y;
            mCommands.push( function(g:Graphics,f:Float)
               { g.moveTo(x+(px-x)*f, y+(py-y)*f); } );
         }
         else
         {
            // if (is_move) throw("edge found when move expected");

            // straight
            if (inStream.ReadBool())
            {
               var delta_bits = inStream.Bits(4) + 2;
               var x0 = pen_x;
               var y0 = pen_y;
               if (inStream.ReadBool())
               {
                  pen_x += inStream.Twips(delta_bits);
                  pen_y += inStream.Twips(delta_bits);
               }
               else if (inStream.ReadBool())
                  pen_y += inStream.Twips(delta_bits);
               else
                  pen_x += inStream.Twips(delta_bits);
 
               var px = pen_x;
               var py = pen_y;
               if (!is_line)
               {
                  var cx2 = (px+x0)*0.5;
                  var cy2 = (py+y0)*0.5;
                  mCommands.push( function(g:Graphics,f:Float)
                     { g.curveTo(cx+(cx2-cx)*f, cy+(cy2-cy)*f,
                              x+(px-x)*f, y+(py-y)*f); } );
               }
               else
                  mCommands.push( function(g:Graphics,f:Float)
                     { g.lineTo(x+(px-x)*f, y+(py-y)*f); } );
               // trace("End: lineTo " + pen_x + "," + pen_y);
            }
            // Curved ...
            else
            {
               var delta_bits = inStream.Bits(4) + 2;
               var cx2 = pen_x + inStream.Twips(delta_bits);
               var cy2 = pen_y + inStream.Twips(delta_bits);
               var px = cx2 + inStream.Twips(delta_bits);
               var py = cy2 + inStream.Twips(delta_bits);
               // Can't push "pen_x/y" in closure because it uses a reference
               //  to the member variable, not a copy of the current value.
               pen_x = px;
               pen_y = py;

               mCommands.push( function(g:Graphics,f:Float)
                  { g.curveTo(cx+(cx2-cx)*f, cy+(cy2-cy)*f,
                              x+(px-x)*f, y+(py-y)*f); } );
               // trace("End: curveTo " + pen_x + "," + pen_y);
            }

         }
      }

      for(e in edges)
      {
         switch(e)
         {
            case meStyle(func):
               // trace("  pop final func");
               mCommands.push(func);

            default:
               throw("Edge count mismatch");
         }
      }

      mSWF = null;

      // Render( new nme.display.DebugGfx());
   }

   public function Render(inGraphics:Graphics,f:Float)
   {
      mWaitingLoader = false;
      for(c in mCommands)
         c(inGraphics,f);
      return mWaitingLoader;
   }

   static function InterpMatrix(inM0:Matrix,inM1:Matrix,f:Float)
   {
      var m = new Matrix();
      m.a = inM0.a + (inM1.a - inM0.a)*f;
      m.b = inM0.b + (inM1.b - inM0.b)*f;
      m.c = inM0.c + (inM1.c - inM0.c)*f;
      m.d = inM0.d + (inM1.d - inM0.d)*f;
      m.tx= inM0.tx + (inM1.tx - inM0.tx)*f;
      m.ty= inM0.ty + (inM1.ty - inM0.ty)*f;
      return m;
   }

   static function InterpColour(inC0:Int,inC1:Int,f:Float)
   {
      var r0 = (inC0>>16) & 0xff;
      var g0 = (inC0>>8) & 0xff;
      var b0 = (inC0) & 0xff;
      return (Std.int( r0 + (((inC1>>16) & 0xff )-r0)* f )<< 16)|
             (Std.int( g0 + (((inC1>>8 ) & 0xff )-g0)* f )<< 8)|
             (Std.int( b0 + (((inC1    ) & 0xff )-b0)* f ));
   }

   function ReadFillStyles(inStream:SWFStream,inVersion:Int) : MorphRenderFuncList
   {
      var result:MorphRenderFuncList = [];


      // Special null fill-style
      result.push( function(g:Graphics,f:Float) { g.endFill(); } );


      var n = inStream.ReadArraySize(true);
      for(i in 0...n)
      {
         var fill = inStream.ReadByte();
         if (fill==ftSolid)
         {
            var RGB0 = inStream.ReadRGB();
            var A0 = inStream.ReadByte()/255.0;
            var RGB1 = inStream.ReadRGB();
            var A1 = inStream.ReadByte()/255.0;
            var dA = A1 - A0;
            result.push( function(gfx:Graphics,f:Float)
            {
              gfx.beginFill(InterpColour(RGB0,RGB1,f), (A0 + dA*f ));
            } );
         }
         // Gradient
         else if ( (fill & 0x10) !=0 )
         {
            var matrix0 = inStream.ReadMatrix();
            inStream.AlignBits();
            var matrix1 = inStream.ReadMatrix();
            inStream.AlignBits();

            //var spread = inStream.ReadSpreadMethod();
            //var interp = inStream.ReadInterpolationMethod();

            var n = inStream.Bits(4);
            var colors0 = [];
            var colors1 = [];
            var alphas0 = [];
            var alphas1 = [];
            var ratios0 = [];
            var ratios1 = [];
            for(i in 0...n)
            {
               ratios0.push( inStream.ReadByte() );
               colors0.push( inStream.ReadRGB() );
               alphas0.push( inStream.ReadByte()/255.0 );
               ratios1.push( inStream.ReadByte() );
               colors1.push( inStream.ReadRGB() );
               alphas1.push( inStream.ReadByte()/255.0 );
            }
            //var focus = fill==ftRadialF ?  inStream.ReadByte()/255.0 : 0.0;
            //var type = fill==ftLinear ? nme.display.GradientType.LINEAR :
                                         //nme.display.GradientType.RADIAL;

            result.push( function(g:Graphics,f:Float) {
               var cols = [];
               var alphas = [];
               var ratios = [];
               for(i in 0...n)
               {
                  cols.push( InterpColour(colors0[i],colors1[i],f) );
                  alphas.push( alphas0[i] + (alphas1[i]-alphas0[i]) * f );
                  ratios.push( ratios0[i] + (ratios1[i]-ratios0[i]) * f );
               }
               g.beginGradientFill(GradientType.LINEAR,
                       cols,alphas,ratios, InterpMatrix(matrix0,matrix1,f) );
                                   
              } );
         }
         // Bitmap
         else if ( (fill & 0x40)!=0)
         {
            var id = inStream.ReadID();
            var bitmap = mSWF.GetBitmap(id);


            inStream.AlignBits();
            var matrix0 = inStream.ReadMatrix();
            // Not too sure about these.
            // A scale of (20,20) is 1 pixel-per-unit.
            matrix0.a *= 0.05;
            matrix0.b *= 0.05;
            matrix0.c *= 0.05;
            matrix0.d *= 0.05;

            inStream.AlignBits();
            var matrix1 = inStream.ReadMatrix();
            // Not too sure about these.
            // A scale of (20,20) is 1 pixel-per-unit.
            matrix1.a *= 0.05;
            matrix1.b *= 0.05;
            matrix1.c *= 0.05;
            matrix1.d *= 0.05;


            inStream.AlignBits();
            //var repeat = fill == ftBitmapRepeat || fill==ftBitmapRepeatR;
            //var smooth = fill == ftBitmapRepeatR || fill ==ftBitmapClippedR;

            if (bitmap!=null)
            {
               result.push( function(g:Graphics,f:Float) {
                  g.beginBitmapFill(bitmap,InterpMatrix(matrix0,matrix1,f) );});
            }
            // May take some time for bitmap to load ...
            else
            {
               var s = mSWF;
               var me = this;
               result.push( function(g:Graphics,f:Float) {
                  if (bitmap==null)
                  {
                     bitmap = s.GetBitmap(id);
                     if (bitmap==null)
                     {
                        me.mWaitingLoader = true;
                        g.endFill();
                        return;
                     }
                     else
                        me = null;
                  }

               g.beginBitmapFill(bitmap,InterpMatrix(matrix0,matrix1,f)); } );
            }

         }
      }
      return result;
   }

   function ReadLineStyles(inStream:SWFStream,inVersion:Int) : MorphRenderFuncList
   {
      var result:MorphRenderFuncList = [];

      // Special null line-style
      result.push( function(g:Graphics,f:Float) { g.lineStyle(null); } );

      var n = inStream.ReadArraySize(true);
       
      for(i in 0...n)
      {
         if (inVersion==1)
         {
            inStream.AlignBits();
            var w0 = inStream.ReadDepth()*0.05;
            var w1 = inStream.ReadDepth()*0.05;
            var RGB0 = inStream.ReadRGB();
            var A0 = inStream.ReadByte()/255.0;
            var RGB1 = inStream.ReadRGB();
            var A1 = inStream.ReadByte()/255.0;
            result.push( function(g:Graphics,f:Float)
               { g.lineStyle(w0+(w1-w0)*f,InterpColour(RGB0,RGB1,f),
                              A0 + (A1-A0)*f ); } );
         }
         // MorphLinestyle 2
         else
         {
            inStream.AlignBits();
            var w0 = inStream.ReadDepth()*0.05;
            var w1 = inStream.ReadDepth()*0.05;
            //trace(" w0..w1 : " + w0 + "," + w1 );
            var start_caps = inStream.ReadCapsStyle();
            var joints = inStream.ReadJoinStyle();
            var has_fill = inStream.ReadBool();
            var scale = inStream.ReadScaleMode();
            var pixel_hint = inStream.ReadBool();
            var reserved = inStream.Bits(5);
            var no_close = inStream.ReadBool();
            var end_caps = inStream.ReadCapsStyle();
            var miter = joints==JointStyle.MITER ? inStream.ReadDepth()/256.0:1;
            if (!has_fill)
            {
               var c0 = inStream.ReadRGB();
               var A0 =  (inStream.ReadByte()/255.0);
               var c1 = inStream.ReadRGB();
               var A1 =  (inStream.ReadByte()/255.0);

               result.push( function(g:Graphics,f:Float)
                 { g.lineStyle( w0 + (w1-w0)*f, InterpColour(c0,c1,f),
                    A0+(A1-A0)*f,pixel_hint,scale,start_caps,joints,miter);} );
            }
            else
            {
               var fill = inStream.ReadByte();

               // Gradient
               if ( (fill & 0x10) !=0 )
               {
                  var matrix0 = inStream.ReadMatrix();
                  inStream.AlignBits();
                  var matrix1 = inStream.ReadMatrix();
                  inStream.AlignBits();
      
                  //var spread = inStream.ReadSpreadMethod();
                  //var interp = inStream.ReadInterpolationMethod();
      
                  var n = inStream.Bits(4);
                  var colors0 = [];
                  var colors1 = [];
                  var alphas0 = [];
                  var alphas1 = [];
                  var ratios0 = [];
                  var ratios1 = [];
                  for(i in 0...n)
                  {
                     ratios0.push( inStream.ReadByte() );
                     colors0.push( inStream.ReadRGB() );
                     alphas0.push( inStream.ReadByte()/255.0 );
                     ratios1.push( inStream.ReadByte() );
                     colors1.push( inStream.ReadRGB() );
                     alphas1.push( inStream.ReadByte()/255.0 );
                  }
                  //var focus = fill==ftRadialF ?  inStream.ReadByte()/255.0 : 0.0;
                  //var type = fill==ftLinear ? nme.display.GradientType.LINEAR :
                                               //nme.display.GradientType.RADIAL;
      
                  result.push( function(g:Graphics,f:Float) {
                     var cols = [];
                     var alphas = [];
                     var ratios = [];
                     for(i in 0...n)
                     {
                        cols.push( InterpColour(colors0[i],colors1[i],f) );
                        alphas.push( alphas0[i] + (alphas1[i]-alphas0[i]) * f );
                        ratios.push( ratios0[i] + (ratios1[i]-ratios0[i]) * f );
                     }
                     g.lineGradientStyle(GradientType.LINEAR,
                             cols,alphas,ratios, InterpMatrix(matrix0,matrix1,f) );
                                         
                    } );

               }
               else
                  throw("Unknown fillstyle (" + fill + ")");
            }
         }
      }

      return result;
   }

}
