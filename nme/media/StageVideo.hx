package nme.media;

import nme.events.EventDispatcher;
import nme.Vector;
import nme.geom.Point;
import nme.geom.Rectangle;

class StageVideo extends EventDispatcher
{
   public var colorSpaces(get_colorSpaces,null) : Vector<String>;
	public var depth : Int;
	public var videoHeight(default,null) : Int;
	public var videoWidth(default,null) : Int;

	public var viewPort(get_viewPort, set_viewPort) : Rectangle;
	public var pan(get_pan,set_pan) : Point;
	public var zoom(get_zoom,set_zoom) : Point;

   var nmePan:Point;
   var nmeZoom:Point;
   var nmeViewport:Rectangle;

   public function new()
   {
      super();
      depth = 0;
      nmePan = new Point(0,0);
      nmeZoom = new Point(1,1);
      videoWidth = 0;
      videoHeight = 0;
      nmeViewport = new Rectangle(0,0,0,0);
   }

   function get_colorSpaces()
   {
      var colorSpaces = new Vector<String>();
      colorSpaces.push("BT.709");
      return colorSpaces;
   }

	// public function attachAVStream(avStream : AVStream) : Void { }

	public function attachNetStream(netStream : nme.net.NetStream) : Void
   {
   }

	// public function attachCamera(theCamera : Camera) : Void { }

   function get_pan() { return nmePan.clone(); }
   function set_pan(inPan:Point) : Point
   {
      nmePan = inPan.clone();
      return inPan;
   }

   function get_zoom() { return nmeZoom.clone(); }
   function set_zoom(inZoom:Point) : Point
   {
      nmeZoom = inZoom.clone();
      return inZoom;
   }

   function get_viewPort() { return nmeViewport.clone(); }
   function set_viewPort(inVp:Rectangle) : Rectangle
   {
      nmeViewport= inVp.clone();
      return inVp;
   }
}

