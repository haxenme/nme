package pack.cross.components.scroller.model;

import pack.cross.data.Rectangle;
import pack.cross.components.scroller.events.ScrollEvent;

/*
import hsl.haxe.DirectSignaler;
import hsl.haxe.Signaler;
*/

import flash.events.EventDispatcher;

typedef TScroll = {
	total : Rectangle,
	thumb : Rectangle
}

class ScrollModel extends EventDispatcher {
	
	var _minW : Float;
	
	//public var changedSignaler( default, null ) : Signaler<TScroll>;
	public var totalRect( default, set_totalRect ) : Rectangle;
	public var thumbRect( default, set_thumbRect ) : Rectangle;
	public var data( get_data, null ) : TScroll;
	public var maxX( get_maxX, null ) : Float;
	public var minW( get_minW, set_minW ) : Float;
	public var scrollSpace( get_scrollSpace, null ) : Float;
	public var sizeRatio( get_sizeRatio, set_sizeRatio ) : Float;
	public var positionRatio( get_positionRatio, set_positionRatio ) : Float;
	
	public function new( totalRect : Rectangle, thumbRect : Rectangle ) {
		super();
		//this.changedSignaler = new DirectSignaler(this);
		this.totalRect = totalRect;
		this.thumbRect = thumbRect;
		_minW = 10;
	}
	
	function set_totalRect( r : Rectangle ) : Rectangle {
		totalRect = r;
		dispatchEvent( new ScrollEvent({ total : r, thumb : thumbRect}) );
		//changedSignaler.dispatch({ total : r, thumb : thumbRect});
		return r;
	}
	
	function set_thumbRect( r : Rectangle ) : Rectangle {
		thumbRect = r;
		dispatchEvent( new ScrollEvent({ total : totalRect, thumb : r}) );
		//changedSignaler.dispatch({ total : totalRect, thumb : r});
		return r;
	}
	
	function get_data() : TScroll {
		return { total : totalRect, thumb : thumbRect };
	}
	
	function get_maxX() : Float {
		return totalRect.x + totalRect.width - thumbRect.width;
	}
	
	function get_minW() : Float {
		return _minW;
	}
	
	function set_minW( w : Float ) : Float {
		return _minW = w;
	}
	
	public function get_scrollSpace() : Float {
		return totalRect.width - thumbRect.width;
	}
	
	function get_sizeRatio() : Float {
		return thumbRect.width / totalRect.width;
	}
	
	function set_sizeRatio( r : Float ) {
		return thumbRect.width = r * totalRect.width;
	}
	
	function get_positionRatio() : Float {
		if( get_scrollSpace() == 0 ) return 1;
		return (thumbRect.x - totalRect.x) / get_scrollSpace();
	}
	
	function set_positionRatio( r : Float ) {
		return thumbRect.x = r * get_scrollSpace() + totalRect.x;
	}
	
	public function set_thumbPosition( x : Float ) {
		var val = validateX(x);
		if( val != thumbRect.x ) {
			thumbRect.x = validateX(x);
			dispatchEvent( new ScrollEvent(data) );
			//changedSignaler.dispatch(data);
		}
	}
	
	public function set_thumbWidth( w : Float ) {
		var val = validateW(w);
		if( val != thumbRect.width ) {
			thumbRect.width = validateW(w);
			dispatchEvent( new ScrollEvent(data) );
			//changedSignaler.dispatch(data);
		}
	}
	
	public function sizeThumbLeft( xPos : Float ) {
		var rightX = thumbRect.x + thumbRect.width;
		if( (rightX - xPos) < minW )
			xPos = rightX - minW;
		if( xPos < totalRect.x )
			xPos = totalRect.x;
		thumbRect.x = xPos;
		thumbRect.width = rightX - thumbRect.x;
		dispatchEvent( new ScrollEvent(data) );
		//changedSignaler.dispatch(data);
	}
	
	public function validateX( x : Float ) : Float {
		if( x < totalRect.x ) return totalRect.x;
		if( x > maxX ) return maxX;
		return x;
	}
	
	public function validateW( w : Float ) : Float {
		if( (thumbRect.x + w) > (totalRect.x + totalRect.width) ) return totalRect.x + totalRect.width - thumbRect.x;
		if( w < minW ) return minW;
		return w;
	}
}
