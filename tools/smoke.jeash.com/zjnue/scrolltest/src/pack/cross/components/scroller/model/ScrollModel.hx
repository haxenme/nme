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
	public var totalRect( default, setTotalRect ) : Rectangle;
	public var thumbRect( default, setThumbRect ) : Rectangle;
	public var data( getData, null ) : TScroll;
	public var maxX( getMaxX, null ) : Float;
	public var minW( getMinW, setMinW ) : Float;
	public var scrollSpace( getScrollSpace, null ) : Float;
	public var sizeRatio( getSizeRatio, setSizeRatio ) : Float;
	public var positionRatio( getPositionRatio, setPositionRatio ) : Float;
	
	public function new( totalRect : Rectangle, thumbRect : Rectangle ) {
		super();
		//this.changedSignaler = new DirectSignaler(this);
		this.totalRect = totalRect;
		this.thumbRect = thumbRect;
		_minW = 10;
	}
	
	function setTotalRect( r : Rectangle ) : Rectangle {
		totalRect = r;
		dispatchEvent( new ScrollEvent({ total : r, thumb : thumbRect}) );
		//changedSignaler.dispatch({ total : r, thumb : thumbRect});
		return r;
	}
	
	function setThumbRect( r : Rectangle ) : Rectangle {
		thumbRect = r;
		dispatchEvent( new ScrollEvent({ total : totalRect, thumb : r}) );
		//changedSignaler.dispatch({ total : totalRect, thumb : r});
		return r;
	}
	
	function getData() : TScroll {
		return { total : totalRect, thumb : thumbRect };
	}
	
	function getMaxX() : Float {
		return totalRect.x + totalRect.width - thumbRect.width;
	}
	
	function getMinW() : Float {
		return _minW;
	}
	
	function setMinW( w : Float ) : Float {
		return _minW = w;
	}
	
	public function getScrollSpace() : Float {
		return totalRect.width - thumbRect.width;
	}
	
	function getSizeRatio() : Float {
		return thumbRect.width / totalRect.width;
	}
	
	function setSizeRatio( r : Float ) {
		return thumbRect.width = r * totalRect.width;
	}
	
	function getPositionRatio() : Float {
		if( getScrollSpace() == 0 ) return 1;
		return (thumbRect.x - totalRect.x) / getScrollSpace();
	}
	
	function setPositionRatio( r : Float ) {
		return thumbRect.x = r * getScrollSpace() + totalRect.x;
	}
	
	public function setThumbPosition( x : Float ) {
		var val = validateX(x);
		if( val != thumbRect.x ) {
			thumbRect.x = validateX(x);
			dispatchEvent( new ScrollEvent(data) );
			//changedSignaler.dispatch(data);
		}
	}
	
	public function setThumbWidth( w : Float ) {
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
