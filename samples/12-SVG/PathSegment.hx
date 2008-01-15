// This code borrowed from "Xinf", http://xinf.org
// Copyright of original author.
// package xinf.ony;

enum PathSegment {

    MoveTo( x:Float, y:Float );
    MoveToR( x:Float, y:Float );
    Close;
    
    LineTo( x:Float, y:Float );
    LineToR( x:Float, y:Float );
    HorizontalTo( x:Float );
    HorizontalToR( x:Float );
    VerticalTo( y:Float );
    VerticalToR( y:Float );
    
    CubicTo( x1:Float, y1:Float, x2:Float, y2:Float, x:Float, y:Float );
    CubicToR( x1:Float, y1:Float, x2:Float, y2:Float, x:Float, y:Float );
    SmoothCubicTo( x2:Float, y2:Float, x:Float, y:Float );
    SmoothCubicToR( x2:Float, y2:Float, x:Float, y:Float );
    
    QuadraticTo( x1:Float, y1:Float, x:Float, y:Float );
    QuadraticToR( x1:Float, y1:Float, x:Float, y:Float );
    SmoothQuadraticTo( x:Float, y:Float );
    SmoothQuadraticToR( x:Float, y:Float );
    
    ArcTo( rx:Float, ry:Float, rotation:Float, largeArc:Bool, sweep:Bool, x:Float, y:Float );
    ArcToR( rx:Float, ry:Float, rotation:Float, largeArc:Bool, sweep:Bool, x:Float, y:Float );

}


