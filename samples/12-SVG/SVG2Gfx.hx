import Xml;
import PathParser;
import PathSegment;

typedef Matrix = nme.Matrix;
typedef GradientType = nme.GradientType;
typedef SpreadMethod = nme.SpreadMethod;
typedef InterpolationMethod = nme.InterpolationMethod;
typedef CapsStyle = nme.CapsStyle;
typedef JointStyle = nme.JointStyle;


typedef Grad =
{
   var type:GradientType;
   var cols:Array<Int>;
   var alphas:Array<Float>;
   var ratios:Array<Int>;
   var matrix: Matrix;
   var spread: SpreadMethod;
   var interp:InterpolationMethod;
   var radius:Float;
   var x1:Float;
   var y1:Float;
   var x2:Float;
   var y2:Float;
}

typedef GradHash = Hash<Grad>;

enum FillType
{
   FillGrad(grad:Grad);
   FillSolid(colour:Int);
   FillNone;
   // Bitmap
}

typedef PathSegments = Array<PathSegment>;

typedef Path =
{
   var fill:FillType;
   var fill_alpha:Float;
   var stroke_alpha:Float;
   var stroke_colour:Null<Int>;
   var stroke_width:Float;
   var stroke_caps:String;
   var joint_style:String;
   var miter_limit:Float;
   var matrix:Matrix;

   var segments:PathSegments;
}

typedef Group =
{
   var name:String;
   var children:Array<DisplayElement>;
}

enum DisplayElement
{
   DisplayPath(path:Path);
   DisplayGroup(group:Group);
}

typedef DisplayElements = Array<DisplayElement>;

typedef Styles = Hash<String>;


class SVG2Gfx
{
    var mXML:Xml;

    var mScaleX:Float;
    var mScaleY:Float;
    public var width(default,null):Float;
    public var height(default,null):Float;

    var mGrads : GradHash;
    var mPathParser: PathParser;

    var mRoot:Array<Group>;

    var mGfx : Dynamic;
    var mMatrix : Matrix;

    static var mStyleSplit = ~/;/g;
    static var mStyleValue = ~/\s*(.*)\s*:\s*(.*)\s*/;

    static var mTranslateMatch = ~/translate\((.*),(.*)\)/;
    static var mScaleMatch = ~/scale\((.*)\)/;
    static var mMatrixMatch = ~/matrix\((.*),(.*),(.*),(.*),(.*),(.*)\)/;
    static var mURLMatch = ~/url\(#(.*)\)/;

    public function new(inXML:Xml)
    {
       mXML = inXML;
       var svg =  mXML.firstElement();
       if (svg==null || svg.nodeName!="svg")
          throw "Not an SVG file\n";

       mGrads = new GradHash();

       mPathParser = new PathParser();

       mRoot = new Array();

       width = GetFloatStyle("width",svg,null,0.0);
       height = GetFloatStyle("height",svg,null,0.0);
       if (width==0 && height==0)
          width = height = 400;
       else if (width==0)
          width = height;
       else if (height==0)
          height = width;

       for(element in svg.elements())
       {
          var name = element.nodeName;
          if (name=="defs")
             LoadDefs(element);
          else if (name=="g")
          {
             mRoot.push( LoadGroup(element,new Matrix(), null)  );
          }
       }
    }

    function LoadGradient(inGrad:Xml,inType:GradientType)
    {
       var name = inGrad.get("id");
       var grad = { type:inType,
                    cols : [],
                    alphas : [],
                    ratios : [],
                    matrix : new Matrix(),
                    spread : SpreadMethod.PAD,
                    interp : InterpolationMethod.RGB,
                    radius : 1.0,
                    x1 : 0.0,
                    y1 : 0.0,
                    x2 : 0.0,
                    y2 : 0.0,
                    };

       if (inGrad.exists("xlink:href"))
       {
          var xlink = inGrad.get("xlink:href");
          if (xlink.charAt(0)!="#")
             throw("xlink - unkown syntax : " + xlink );
          var base = mGrads.get(xlink.substr(1));
          if (base==null)
             throw("Unknown xlink : " + xlink);
          grad.cols = base.cols;
          grad.alphas = base.alphas;
          grad.ratios = base.ratios;
          grad.matrix = base.matrix.clone();
          grad.spread = base.spread;
          grad.interp = base.interp;
          grad.radius = base.radius;
       }

       if (inGrad.exists("x1"))
       {
          grad.x1 = Std.parseFloat(inGrad.get("x1"));
          grad.y1 = Std.parseFloat(inGrad.get("y1"));
          grad.x2 = Std.parseFloat(inGrad.get("x2"));
          grad.y2 = Std.parseFloat(inGrad.get("y2"));
       }
       if (inGrad.exists("cx"))
       {
          grad.x1 = Std.parseFloat(inGrad.get("cx"));
          grad.y1 = Std.parseFloat(inGrad.get("cy"));
          grad.x2 = Std.parseFloat(inGrad.get("fx"));
          grad.y2 = Std.parseFloat(inGrad.get("fy"));
       }
       if (inGrad.exists("r"))
          grad.radius = Std.parseFloat(inGrad.get("r"));


       if (inGrad.exists("gradientTransform"))
          ApplyTransform(grad.matrix,inGrad.get("gradientTransform"));


       // todo - grad.spread = base.spread;

       for(stop in inGrad.elements())
       {
          var styles = GetStyles(stop,null);

          grad.cols.push( GetColourStyle("stop-color",stop,styles,0x000000) );
          grad.alphas.push( GetFloatStyle("stop-opacity",stop,styles,1.0) );
          grad.ratios.push(
             Std.int( Std.parseFloat(stop.get("offset") ) * 255.0) );
       }


       mGrads.set(name,grad);
    }

    function LoadDefs(inXML:Xml)
    {
       for(def in inXML.elements())
       {
          var name = def.nodeName;
          if (name=="linearGradient")
             LoadGradient(def,GradientType.LINEAR);
          else if (name=="radialGradient")
             LoadGradient(def,GradientType.RADIAL);
       }

    }

    function ApplyTransform(ioMatrix:Matrix, inTrans:String)
    {
       if (mTranslateMatch.match(inTrans))
       {
          ioMatrix.translate(
                  Std.parseFloat( mTranslateMatch.matched(1) ),
                  Std.parseFloat( mTranslateMatch.matched(2) ));
       }
       else if (mScaleMatch.match(inTrans))
       {
          var s = Std.parseFloat( mScaleMatch.matched(1) );
          ioMatrix.scale(s,s);
       }
       else if (mMatrixMatch.match(inTrans))
       {
          var m = new Matrix(
                  Std.parseFloat( mMatrixMatch.matched(1) ),
                  Std.parseFloat( mMatrixMatch.matched(3) ),
                  Std.parseFloat( mMatrixMatch.matched(2) ),
                  Std.parseFloat( mMatrixMatch.matched(4) ),
                  Std.parseFloat( mMatrixMatch.matched(5) ),
                  Std.parseFloat( mMatrixMatch.matched(6) ) );
          ioMatrix.concat(m);
       }
       else 
          trace("Warning, unknown transform:" + inTrans);
    }


   function GetStyles(inNode:Xml,inPrevStyles:Styles) : Styles
   {
      if (!inNode.exists("style"))
         return inPrevStyles;

      var styles = new Styles();
      if (inPrevStyles!=null)
         for(s in inPrevStyles.keys())
            styles.set(s,inPrevStyles.get(s));

      var style = inNode.get("style");
      var strings = mStyleSplit.split(style);
      for(s in strings)
      {
         if (mStyleValue.match(s))
            styles.set(mStyleValue.matched(1),mStyleValue.matched(2));
      }

      return styles;
   }

   function GetStyle(inKey:String,inNode:Xml,inStyles:Styles,inDefault:String)
   {
      if (inNode!=null && inNode.exists(inKey))
      {
         return inNode.get(inKey);
      }

      if (inStyles!=null && inStyles.exists(inKey))
         return inStyles.get(inKey);
 
      //trace("Key not found : " + inKey);
      //trace(inStyles);
      //throw("not found");

      return inDefault;
   }

   function GetFloatStyle(inKey:String,inNode:Xml,inStyles:Styles,
               inDefault:Float)
   {
      var s = GetStyle(inKey,inNode,inStyles,"");
      if (s=="")
         return inDefault;
      return Std.parseFloat(s);
   }

   function GetColourStyle(inKey:String,inNode:Xml,inStyles:Styles,
               inDefault:Int)
   {
      var s = GetStyle(inKey,inNode,inStyles,"");
      if (s=="")
         return inDefault;
      if (s.charAt(0)=='#')
         return Std.parseInt( "0x" + s.substr(1) );
         
      return Std.parseInt(s);
   }

   function GetStrokeStyle(inKey:String,inNode:Xml,inStyles:Styles,
               inDefault:Null<Int>)
   {
      var s = GetStyle(inKey,inNode,inStyles,"");
      if (s=="")
         return inDefault;

      if (s=="none")
         return null;

      if (s.charAt(0)=='#')
         return Std.parseInt( "0x" + s.substr(1) );

      return Std.parseInt(s);
   }

   function GetFillStyle(inKey:String,inNode:Xml,inStyles:Styles)
   {
      var s = GetStyle(inKey,inNode,inStyles,"");
      if (s=="")
         return FillNone;

      if (s.charAt(0)=='#')
         return FillSolid( Std.parseInt( "0x" + s.substr(1) ) );
 
      if (s=="none")
         return FillNone;

      if (mURLMatch.match(s))
      {
         var url = mURLMatch.matched(1);
         if (mGrads.exists(url))
            return FillGrad(mGrads.get(url));
         
         throw("Unknown url:" + url);
      }

      throw("Unknown fill string:" + s);

      return FillNone;
   }



    public function LoadPath(inPath:Xml, matrix:Matrix,inStyles:Styles,inIsRect:Bool) : Path
    {
       if (inPath.exists("transform"))
       {
          matrix = matrix.clone();
          ApplyTransform(matrix,inPath.get("transform"));
       }

       var styles = GetStyles(inPath,inStyles);

       var path =
       {
          fill:GetFillStyle("fill",inPath,styles),
          fill_alpha: GetFloatStyle("fill-opacity",inPath,styles,1.0),
          stroke_alpha: GetFloatStyle("stroke-opacity",inPath,styles,1.0),
          stroke_colour:GetStrokeStyle("stroke",inPath,styles,null),
          stroke_width: GetFloatStyle("stroke-width",inPath,styles,1.0),
          stroke_caps:CapsStyle.ROUND,
          joint_style:JointStyle.ROUND,
          miter_limit: GetFloatStyle("stroke-miterlimit",inPath,styles,3.0),
          segments:[],
          matrix:matrix,
       }

       if (inIsRect)
       {
          var x = Std.parseFloat(inPath.get("x"));
          var y = Std.parseFloat(inPath.get("y"));
          var w = Std.parseFloat(inPath.get("width"));
          var h = Std.parseFloat(inPath.get("height"));
          path.segments.push( MoveTo(x,y) );
          path.segments.push( LineTo(x+w,y) );
          path.segments.push( LineTo(x+w,y+h) );
          path.segments.push( LineTo(x,y+h) );
          path.segments.push( LineTo(x,y) );
       }
       else
       {
          var d = inPath.get("d");
          for(segment in mPathParser.parse(d) )
             path.segments.push(segment);
       }

       return path;
    }

    public function LoadGroup(inG:Xml, matrix:Matrix,inStyles:Styles) : Group
    {
       var g:Group = { children: [], name:"" };
       if (inG.exists("transform"))
       {
          matrix = matrix.clone();
          ApplyTransform(matrix,inG.get("transform"));
       }
       if (inG.exists("id"))
          g.name = inG.get("id");

       var styles = GetStyles(inG,inStyles);

       for(el in inG.elements())
       {
          if (el.nodeName=="g")
          {
             g.children.push( DisplayGroup(LoadGroup(el,matrix, styles)) );
          }
          else if (el.nodeName=="path")
          {
             g.children.push( DisplayPath( LoadPath(el,matrix, styles, false) ) );
          }
          else if (el.nodeName=="rect")
          {
             g.children.push( DisplayPath( LoadPath(el,matrix, styles, true) ) );
          }
          else
          {
             // throw("Unknown child : " + el.nodeName );
          }
       }

       return g;
    }

    var mPenX:Float;
    var mPenY:Float;
    var mLastMoveX:Float;
    var mLastMoveY:Float;
    var mPrevP2X:Float;
    var mPrevP2Y:Float;

    function DoMoveTo(m:Matrix,x:Float,y:Float)
    {
       mPenX = m.a*x + m.b*y + m.tx;
       mPenY = m.c*x + m.d*y + m.ty;
       mLastMoveX = mPenX;
       mLastMoveY = mPenY;
       mGfx.moveTo(mPenX,mPenY);
    }

    function DoLineTo(m:Matrix,x:Float,y:Float)
    {
       mPenX = m.a*x + m.b*y + m.tx;
       mPenY = m.c*x + m.d*y + m.ty;
       mGfx.lineTo(mPenX,mPenY);
    }

    function DoQuadraticTo(xc:Float,yc:Float,x:Float,y:Float)
    {
       mPrevP2X = xc;
       mPrevP2Y = yc;
       mPenX = x;
       mPenY = y;
       mGfx.curveTo(xc,yc,x,y);
    }


    function DoCubicTo( x1:Float,y1:Float, x2:Float,y2:Float, x3:Float,y3:Float)
    {
       var dx1 = x1-mPenX;
       var dy1 = y1-mPenY;
       var dx2 = x2-x1;
       var dy2 = y2-y1;
       var dx3 = x3-x2;
       var dy3 = y3-y2;
       var len = Math.sqrt(dx1*dx1+dy1*dy1 + dx2*dx2+dy2*dy2 + dx3*dx3+dy3*dy3);
       var steps = Math.round(len*0.4);

       if (steps>1)
       {
          var du = 1.0/steps;
          var u = du;
          for(i in 1...steps)
          {
             var u1 = 1.0-u;
             var c0 = u1*u1*u1;
             var c1 = 3*u1*u1*u;
             var c2 = 3*u1*u*u;
             var c3 = u*u*u;
             u+=du;
             mGfx.lineTo(c0*mPenX + c1*x1 + c2*x2 + c3*x3,
                         c0*mPenY + c1*y1 + c2*y2 + c3*y3 );
          }
       }

       mPrevP2X = x2;
       mPrevP2Y = y2;
       mPenX = x3;
       mPenY = y3;
       mGfx.lineTo(mPenX,mPenY);
    }

    function MDoCubicTo(m:Matrix,
                       inX1:Float,inY1:Float,
                       inX2:Float,inY2:Float,
                       inX3:Float,inY3:Float)
    {
       DoCubicTo(m.a*inX1 + m.b*inY1 + m.tx, m.c*inX1 + m.d*inY1 + m.ty,
                 m.a*inX2 + m.b*inY2 + m.tx, m.c*inX2 + m.d*inY2 + m.ty,
                 m.a*inX3 + m.b*inY3 + m.tx, m.c*inX3 + m.d*inY3 + m.ty );
    }

    function SMDoCubicTo(m:Matrix,
                       inX2:Float,inY2:Float,
                       inX3:Float,inY3:Float)
    {
       DoCubicTo(mPenX*2-mPrevP2X, mPenY*2-mPrevP2Y,
                 m.a*inX2 + m.b*inY2 + m.tx, m.c*inX2 + m.d*inY2 + m.ty,
                 m.a*inX3 + m.b*inY3 + m.tx, m.c*inX3 + m.d*inY3 + m.ty );
    }

    function MDoQuadraticTo(m:Matrix,
                       inX1:Float,inY1:Float,
                       inX2:Float,inY2:Float )
    {
       DoQuadraticTo(m.a*inX1 + m.b*inY1 + m.tx, m.c*inX1 + m.d*inY1 + m.ty,
                 m.a*inX2 + m.b*inY2 + m.tx, m.c*inX2 + m.d*inY2 + m.ty );
    }

    function SMDoQuadraticTo(m:Matrix, inX1:Float,inY1:Float )
    {
       DoQuadraticTo(mPenX*2-mPrevP2X, mPenY*2-mPrevP2Y,
                     m.a*inX1 + m.b*inY1 + m.tx, m.c*inX1 + m.d*inY1 + m.ty );
    }



    function DoArcTo(m:Matrix,x1:Float,y1:Float,x2:Float,y2:Float,
                rx:Float, ry:Float,
                phi:Float, fA:Bool, fS:Bool)
    {
       if (rx==0 || ry==0)
       {
          DoLineTo(m,x2,y2);
          return;
       }
       if (rx<0) rx = -rx;
       if (ry<0) ry = -ry;

       var p = phi*Math.PI/180.0;
       var cos = Math.cos(p);
       var sin = Math.sin(p);
       var dx = (x1-x2)*0.5;
       var dy = (y1-y2)*0.5;
       var x1_ = cos*dx + sin*dy;
       var y1_ = -sin*dx + cos*dy;

       var rx2 = rx*rx;
       var ry2 = ry*ry;
       var x1_2 = x1_*x1_;
       var y1_2 = y1_*y1_;
       var s = (rx2*ry2 - rx2*y1_2 - ry2*x1_2) /
                 (rx2*y1_2 + ry2*x1_2 );
       if (s<0)
          s=0;
       else if (fA==fS)
          s = -Math.sqrt(s);
       else
          s = Math.sqrt(s);

       var cx_ = s*rx*y1_/ry;
       var cy_ = -s*ry*x1_/rx;

       // Something not quite right here.
       // See:  http://www.w3.org/TR/SVG/implnote.html#ArcImplementationNotes
       var xm = (x1+x2)*0.5;
       var ym = (y1+y2)*0.5;

       var cx = cos*cx_ + sin*cy_ + xm;
       var cy = -sin*cx_ + cos*cy_ + ym;

       var theta = Math.atan2( (y1_-cy_)/ry, (x1_-cx_)/rx );
       var dtheta = Math.atan2( (-y1_-cy_)/ry, (-x1_-cx_)/rx ) - theta;

       if (fS && dtheta<0)
          dtheta+=2.0*Math.PI;
       else if (!fS && dtheta>0)
          dtheta-=2.0*Math.PI;


       // axis, at theta = 0;
       //
       // p =  [ M ] [ + centre ] [ rotate phi ] [ rx 0 ] [ cos(theta),sin(theta) ]t
       //                                        [ 0 ry ]
       //   = [ a b tx ] [ cos*rx  sin*ry cx ]  [ cos(theta), sin(theta) 1 ]t;
       //     [ c d ty ] [-sin*rx  cos*ry cy ]
       //     [ 0 0 1  ] [ 0       0       1 ]
       //
       var ta = m.a*cos*rx - m.b*sin*rx;
       var tb = m.a*sin*ry + m.b*cos*ry;
       var tx = m.a*cx     + m.b*cy + m.tx;

       var tc = m.c*cos*rx - m.d*sin*rx;
       var td = m.c*sin*ry + m.d*cos*ry;
       var ty = m.c*cx     + m.d*cy + m.ty;

       var len = Math.abs(dtheta)*Math.sqrt(ta*ta + tb*tb + tc*tc + td*td);
       var steps = Math.round(len);

       if (steps>1)
       {
          dtheta /= steps;
          for(i in 1...steps-1)
          {
             var c = Math.cos(theta);
             var s = Math.sin(theta);
             theta+=dtheta;
             mGfx.lineTo( ta*c + tb*s + tx, tc*c + td*s + ty );
          }
       }
       DoLineTo(m,x2,y2);
    }             


    function DoClose()
    {
       if (mPenX!=mLastMoveX || mPenY!=mLastMoveY)
       {
          mPenY = mLastMoveX;
          mPenY = mLastMoveY;
          mGfx.lineTo(mPenX,mPenY);
       }
    }


    public function RenderPath(inPath:Path)
    {
       var px = 0.0;
       var py = 0.0;

       var m:Matrix  = inPath.matrix.clone();
       m.concat(mMatrix);

       switch(inPath.fill)
       {
          case FillGrad(grad):
             var gm:Matrix  = grad.matrix.clone();
             gm.concat(m);

             var mtx = new Matrix();
             var focal = 0.0;

             if (grad.type == GradientType.LINEAR)
             {
                // Transform the points - otherwise we will need to inverse transform
                //  tre gradient matrix ...
                var tx1 = grad.x1 * gm.a + grad.y1*gm.b + gm.tx;
                var ty1 = grad.x1 * gm.c + grad.y1*gm.d + gm.ty;
                var tx2 = grad.x2 * gm.a + grad.y2*gm.b + gm.tx;
                var ty2 = grad.x2 * gm.c + grad.y2*gm.d + gm.ty;
                // G(x,y) = A x + B y + C
             
                var dx = tx2-tx1;
                var dy = ty2-ty1;

                // For linear case, dx,dy is the gradient vector
                if (dx!=0 || dy!=0)
                {
                   var scale = 1.0/(dx*dx+dy*dy);
                   mtx.a = scale*dx;
                   mtx.b = scale*dy;
                   mtx.tx =  - tx1*mtx.a - ty1*mtx.b;
                }
             }
             else
             {

                // Invert matrix...
                var denom = gm.a*gm.d - gm.b*gm.c;
                if (denom!=0)
                {
                   denom = 1.0/denom;
                   var a = gm.d*denom;
                   var b = -gm.b*denom;
                   var c = -gm.c*denom;
                   var d = gm.a*denom;
                   mtx = new Matrix( a, b, c, d, 
                       -a*gm.tx-b*gm.ty, -c*gm.tx-d*gm.ty );
                }

                mtx.translate(-grad.x1,-grad.y1);

                var s = 1/grad.radius;
                mtx.scale(s,s);

                var dx = grad.x2-grad.x1;
                var dy = grad.y2-grad.y1;
                if (dx!=0 || dy!=0)
                {
                   var theta = Math.atan2(dy,dx);
                   mtx.rotate(-theta);
                   focal = Math.sqrt(dx*dy+dy*dy)/grad.radius;
                }
             }

             mGfx.beginGradientFill(grad.type, grad.cols, grad.alphas,
                      grad.ratios, mtx, grad.spread, grad.interp, focal );

          case FillSolid(colour):
             mGfx.beginFill(colour,inPath.fill_alpha);
          case FillNone:
             mGfx.endFill();
       }

       if (inPath.stroke_colour==null)
          mGfx.lineStyle(0,0,0,false,"normal",null,null,3);
       else
       {
          var scale = Math.sqrt(m.a*m.a + m.b*m.b);
          mGfx.lineStyle( inPath.stroke_width*scale, inPath.stroke_colour,
                          inPath.stroke_alpha, false,"normal",
                          inPath.stroke_caps,inPath.joint_style,
                          inPath.miter_limit);
       }

       for(segment in inPath.segments)
       {
          switch(segment)
          {
             case MoveTo(x,y):
                px = x; py = y;
                DoMoveTo(m,px,py);

             case MoveToR(x,y):
                px += x; py += y;
                DoMoveTo(m,px,py);

             case Close:
                DoClose();
    
             case LineTo(x,y):
                px = x; py = y;
                DoLineTo(m,px,py);

             case LineToR(x,y):
                px += x; py += y;
                DoLineTo(m,px,py);

             case HorizontalTo(x):
                px = x;
                DoLineTo(m,px,py);

             case HorizontalToR(x):
                px += x;
                DoLineTo(m,px,py);

             case VerticalTo(y):
                py = y;
                DoLineTo(m,px,py);

             case VerticalToR(y):
                py += y;
                DoLineTo(m,px,py);
    
             case CubicTo(x1, y1, x2, y2, x, y):
                px = x; py = y;
                MDoCubicTo(m,x1,y1,x2,y2,px,py);

             case CubicToR(x1, y1, x2, y2, x, y):
                x1 += px; y1 += py;
                x2 += px; y2 += py;
                px += x; py += y;
                MDoCubicTo(m,x1,y1,x2,y2,px,py);

             case SmoothCubicTo( x2, y2, x, y):
                px = x; py = y;
                SMDoCubicTo(m,x2,y2,px,py);


             case SmoothCubicToR( x2, y2, x, y):
                x2 += px; y2 += py;
                px += x; py += y;
                SMDoCubicTo(m,x2,y2,px,py);
    
             case QuadraticTo( x1, y1, x, y):
                px = x; py = y;
                MDoQuadraticTo(m,x1,y1,px,py);


             case QuadraticToR( x1, y1, x, y):
                x1 += px; y1+=py;
                px += x; py += y;
                MDoQuadraticTo(m,x1,y1,px,py);

             case SmoothQuadraticTo( x, y):
                px = x; py = y;
                SMDoQuadraticTo(m,px,py);

             case SmoothQuadraticToR( x, y):
                px += x; py += y;
                SMDoQuadraticTo(m,px,py);
    
             case ArcTo( rx, ry, rotation, largeArc, sweep, x, y):
                DoArcTo(m,px,py,x,y,rx,ry,rotation,largeArc,sweep);
                px = x; py = y;

             case ArcToR( rx, ry, rotation, largeArc, sweep, x, y):
                x+=px; y+=py;
                DoArcTo(m,px,py,x,y,rx,ry,rotation,largeArc,sweep);
                px = x; py = y;

          }
      }
    }

    public function RenderGroup(inGroup:Group)
    {
       // trace( inGroup.name);

       for(child in inGroup.children)
       {
          switch(child)
          {
             case DisplayGroup(group):
                RenderGroup(group);
             case DisplayPath(path):
                RenderPath(path);
          }
       }
    }

    public function Render(inGfx:Dynamic,inMatrix:Matrix,
        ?inScaleX:Float,?inScaleY:Float)
    {
       mScaleX = inScaleX==null ? 1.0 : mScaleX;
       mScaleY = inScaleY==null ? 1.0 : mScaleY;
       mGfx = inGfx;
       mMatrix = inMatrix;

       for(g in mRoot)
          RenderGroup(g);
    }

}
