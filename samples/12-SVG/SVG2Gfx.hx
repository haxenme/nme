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
   var focal:Float;
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

    var mGrads : GradHash;
    var mPathParser: PathParser;

    var mRoot:Group;

    var mGfx : Dynamic;
    var mMatrix : Matrix;

    static var mStyleSplit = ~/;/g;
    static var mStyleValue = ~/:/;

    static var mTranslateMatch = ~/translate\((.*),(.*)\)/;
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

       for(element in svg.elements())
       {
          var name = element.nodeName;
          if (name=="defs")
             LoadDefs(element);
          else if (name=="g")
             mRoot = LoadGroup(element,new Matrix());
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
                    focal : 0.0 };

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
          grad.focal = base.focal;
       }

       if (inGrad.exists("gradientTransform"))
          ApplyTransform(grad.matrix,inGrad.get("gradientTransform"));

       // todo - grad.spread = base.spread;

       for(stop in inGrad.elements())
       {
          var styles = GetStyles(stop);

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
             LoadGradient(def,GradientType.LINEAR);
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


   function GetStyles(inNode:Xml) : Styles
   {
      if (!inNode.exists("style"))
         return null;

      var styles = new Styles();

      var style = inNode.get("style");
      var strings = mStyleSplit.split(style);
      for(s in strings)
      {
         if (mStyleValue.match(s))
            styles.set(mStyleValue.matchedLeft(),mStyleValue.matchedRight());
      }

      return styles;
   }

   function GetStyle(inKey:String,inNode:Xml,inStyles:Styles,inDefault:String)
   {
      if (inNode!=null && inNode.exists(inKey))
         return inNode.get(inKey);

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



    public function LoadPath(inPath:Xml, inMatrix:Matrix) : Path
    {
       var styles = GetStyles(inPath);

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
          matrix:inMatrix,
       }

       var d = inPath.get("d");
       for(segment in mPathParser.parse(d) )
          path.segments.push(segment);

       return path;
    }

    public function LoadGroup(inG:Xml, matrix:Matrix) : Group
    {
       var g:Group = { children: [], name:"" };
       if (inG.exists("transform"))
       {
          matrix = matrix.clone();
          ApplyTransform(matrix,inG.get("transform"));
       }
       if (inG.exists("id"))
          g.name = inG.get("id");

       for(el in inG.elements())
       {
          if (el.nodeName=="g")
          {
             g.children.push( DisplayGroup(LoadGroup(el,matrix)) );
          }
          else if (el.nodeName=="path")
          {
             g.children.push( DisplayPath( LoadPath(el,matrix) ) );
          }
          else
          {
             throw("Unknown child : " + el.nodeName );
          }
       }

       return g;
    }

    var mPenX:Float;
    var mPenY:Float;
    var mLastMoveX:Float;
    var mLastMoveY:Float;

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


    function DoClose()
    {
       mPenY = mLastMoveX;
       mPenY = mLastMoveY;
       mGfx.lineTo(mPenX,mPenY);
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
             // TODO: work this out ...
             var gm:Matrix  = grad.matrix.clone();
             gm.concat(m);
             mGfx.beginGradientFill(grad.type, grad.cols, grad.alphas,
                      grad.ratios, gm, grad.spread, grad.interp, grad.focal );

          case FillSolid(colour):
             mGfx.beginFill(colour,inPath.fill_alpha);
          case FillNone:
             mGfx.endFill();
       }

       if (inPath.stroke_colour==null)
          mGfx.lineStyle(0,0,0,false,"normal",null,null,3);
       else
          mGfx.lineStyle( inPath.stroke_width, inPath.stroke_colour,
                          inPath.stroke_alpha, false,"normal",
                          inPath.stroke_caps,inPath.joint_style,
                          inPath.miter_limit);

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
                DoLineTo(m,px,py);

             case CubicToR(x1, y1, x2, y2, x, y):
                x1 += px; y1 += py;
                x2 += px; y2 += py;
                px += x; py += y;
                DoLineTo(m,px,py);

             case SmoothCubicTo( x2, y2, x, y):
                px = x; py = y;
                DoLineTo(m,px,py);


             case SmoothCubicToR( x2, y2, x, y):
                x2 += px; y2 += py;
                px += x; py += y;
                DoLineTo(m,px,py);
    
             case QuadraticTo( x1, y1, x, y):
                px = x; py = y;
                DoLineTo(m,px,py);


             case QuadraticToR( x1, y1, x, y):
                x1 += px; y1+=py;
                px += x; py += y;
                DoLineTo(m,px,py);

             case SmoothQuadraticTo( x, y):
                px = x; py = y;
                DoLineTo(m,px,py);

             case SmoothQuadraticToR( x, y):
                px += x; py += y;
                DoLineTo(m,px,py);
    
             case ArcTo( rx, ry, rotation, largeArc, sweep, x, y):
                px = x; py = y;
                //ArcTo(rx,ry,rotation,largeArc,sweep,
                                   //px*m.a+py*m.b+m.tx,px*m.c+py*m.d+m.ty);
          }
      }
    }

    public function RenderGroup(inGroup:Group)
    {
       neko.Lib.println( inGroup.name);

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

    public function Render(inGfx:Dynamic,inMatrix:Matrix,inScaleX:Float,inScaleY:Float)
    {
       mScaleX = inScaleX;
       mScaleY = inScaleY;
       mGfx = inGfx;
       mMatrix = inMatrix;

       RenderGroup(mRoot);
    }

}
