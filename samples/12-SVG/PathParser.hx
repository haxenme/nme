// This code borrowed from "Xinf", http://xinf.org
// Copyright of original author.
//package xinf.ony;
//import xinf.ony.PathSegment;

import PathSegment;

enum PathParserState {
    Empty;
    ParseCommand( cmd:String, nargs:Int );
    ParseFloat( s:String, old:PathParserState );
}

class PathParser {
    static var commandReg = ~/[MmZzLlHhVvCcSsQqTtAa]/;

    var g:Array<PathSegment>;

    var input:String;
    var pin:Int;

    var state:PathParserState;
    var args:Array<Float>;
    
    public function new() {
        state=Empty;
    }

    public function parse( pathToParse:String ) :Iterable<PathSegment> {
        input=pathToParse;
        pin=0;
        args = new Array<Float>();
        g = new Array<PathSegment>();
        
        while( pin<input.length ) {
            var c = input.charAt(pin);
           // trace("CHAR '"+c+"', STATE "+state);
            if( StringTools.isSpace(c,0) || c=="," ) {  // whitespace
                endState();
			} else if( c=="-" ) {            // - (minus) // fixme should trigger new float, except when in exponent like "1.324e-12"
                switch( state ) {
                    case ParseFloat(f,old):
                        if( f.length==0 ) state=ParseFloat("-",old);
						else if( f.charAt(f.length-1)=="e" ) {
							state=ParseFloat(f+c,old);
							pin++;
                        } else {
                            endState();
                            state=ParseFloat("-",state);
                        }
                    default:
                        state=ParseFloat("-",state);
                        pin++;
                }
			} else if( commandReg.match(c) ) {
                endState();
                parseCommand(commandReg.matched(0));
            } else {
                switch( state ) {
                    case ParseFloat(f,old):
                        state = ParseFloat(f+c,old);
                        pin++;
                    default:
                        state = ParseFloat(c,state);
                        pin++;
                }
            }
        }
        endState();
        
        return g;
    }
    
    function parseCommand( cmd:String ) {
        var nargs = switch(cmd.toUpperCase()) {
            case "Z":
                0;
            case "H","V":
                1;
            case "M","L","T":
                2;
            case "S","Q":
                4;
            case "C":
                6;
            case "A":
                7;
        }    
        state = ParseCommand(cmd,nargs);
    }
    
    function fail() {
        throw("failed parsing path '"+input.substr(pin)+"'");
    }
    
    function endState() {
       //trace("END "+state );
        switch( state ) {
        
            case Empty:
                pin++;
                
            case ParseFloat(c,old):
                args.push( Std.parseFloat(c) );
                state = old;
                endState();
                
            case ParseCommand(cmd,nargs):
                if( args.length==nargs ) {
        //            trace("COMMAND "+cmd+", args: "+args );
                    command( cmd, args );
                    args = new Array<Float>();
                    if( nargs==0 ) state=Empty;
                    else if( cmd.toUpperCase()=="M" ) {
                        if( cmd=="M" ) cmd="L";
                        else cmd="l";
                        parseCommand(cmd);
                    }
                } 
                pin++;
                
        }
    }
    
    function command( cmd:String, a:Array<Float> ) {
        var op = 
            switch( cmd ) {
                case "M":
                    MoveTo( a[0], a[1] );
                case "m":
                    MoveToR( a[0], a[1] );
                case "L":
                    LineTo( a[0], a[1] );
                case "l":
                    LineToR( a[0], a[1] );
                case "H":
                    HorizontalTo( a[0] );
                case "h":
                    HorizontalToR( a[0] );
                case "V":
                    VerticalTo( a[0] );
                case "v":
                    VerticalToR( a[0] );
                case "C":
                    CubicTo( a[0], a[1], a[2], a[3], a[4], a[5] );
                case "c":
                    CubicToR( a[0], a[1], a[2], a[3], a[4], a[5] );
                case "S":
                    SmoothCubicTo( a[0], a[1], a[2], a[3] );
                case "s":
                    SmoothCubicToR( a[0], a[1], a[2], a[3] );
                case "Q":
                    QuadraticTo( a[0], a[1], a[2], a[3] );
                case "q":
                    QuadraticToR( a[0], a[1], a[2], a[3] );
                case "T":
                    SmoothQuadraticTo( a[0], a[1] );
                case "t":
                    SmoothQuadraticToR( a[0], a[1] );
                case "A":
                    ArcTo( a[0], a[1], a[2], a[3]==0., a[4]==0., a[5], a[6] );
                case "a":
                    ArcToR( a[0], a[1], a[2], a[3]==0., a[4]==0., a[5], a[6] );
                case "Z":
                    Close;
                case "z":
                    Close;
                default:
                    throw("unimplemented shape command "+cmd);
            }
        
    //                trace("PUSH "+op );
        g.push(op);
    }
}

