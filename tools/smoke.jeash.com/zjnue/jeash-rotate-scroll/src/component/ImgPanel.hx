package component;

import flash.geom.Rectangle;

import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.LoaderInfo;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.MouseEvent;

import flash.net.URLRequest;
import flash.system.LoaderContext;

import haxe.Timer;

import util.DrawUtil;
using util.DrawUtil;

typedef TData = {
	var id : Int;
	var name : String;
	var imgData : BitmapData;
	var selected : Bool;
}

class ImgPanel extends Sprite {
	
	var bounds : Rectangle;
	var imgData : BitmapData;
	var data : Array<TData>;
	var imgY : Float;
	var stubs : Array<Stub>;
	
	var leftButton : ScrollButton;
	var rightButton : ScrollButton;
	var title : TextField;
	var stubStrip : Sprite;
	
	var imageScrollStep : Float;
	var minScrollX : Float;
	
	public function new( bounds : Rectangle ) {
		
		super();
		
		this.bounds = bounds;
		this.imgY = bounds.y + 27;
		
		draw();
		
		loadToad( "../assets/pics/toad.jpg" );
	}
	
	function loadToad( url : String ) {
		var loader = new Loader();
		var loaderInfo = loader.contentLoaderInfo;
		//loaderInfo.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
		//loaderInfo.addEventListener( ProgressEvent.PROGRESS, handleFileProgress );
		loaderInfo.addEventListener( Event.COMPLETE, handleFileComplete );
		var context = new LoaderContext();
		var request = new URLRequest(url);
		context.checkPolicyFile = true;
		loader.load( request, context );
	}
	
	private function handleFileComplete( e : Event ) : Void {
		var file = cast( e.target, LoaderInfo );
		var image = cast( file.content, Bitmap );
		image.smoothing = true;
		imgData = cast( image.bitmapData, BitmapData );
		setData( imgData );
	}
	
	public function draw() {
		
		addChild( leftButton = new ScrollButton( "Scroll left", Orientation.l ) );
		addChild( rightButton = new ScrollButton( "Scroll right", Orientation.r ) );
		addChild( title = new TextField() );
		addChild( stubStrip = new Sprite() );
		stubStrip.visible = false;
		
		leftButton.y = rightButton.y = bounds.y + 4;
		leftButton.x = bounds.x;
		rightButton.x = bounds.width - rightButton.width;
		
		var fmt = new TextFormat( "Arial" );
		fmt.align = TextFormatAlign.CENTER;
		fmt.color = 0x58585A;
		fmt.size = 12;
		
		title.defaultTextFormat = fmt;
		title.selectable = false;
		title.x = bounds.x + 82;
		title.y = bounds.y + 4;
		title.width = bounds.width - 164;
		title.height = 24;
		title.text = "Some instruction text here ...";
		title.correct();
		
		DrawUtil.drawRect( this, bounds.x, bounds.y, bounds.width, bounds.height, 0xffffff, 1.0 );	
	}
	
	function setData( imgData : BitmapData ) {
		
		var selected = false;
		this.data = [];
		for( i in 0...30 ) {
			selected = !selected;
			data.push( {
				id : i, name : "toad" + i, imgData : imgData, selected : selected
			} );
		}
		var imData = data[6].imgData;
		imData.setPixel(0, 4, 0xFF0000);
		imData.setPixel(1, 4, 0xFF0000);
		imData.setPixel(0, 5, 0xFF0000);
		imData.setPixel(1, 5, 0xFF0000);
		
		drawData();
	}
	
	function toggleItem( id : Int ) {
		stubs[id].toggle();
	}
	
	function drawData() {
		
		stubs = [];
		
		var me = this;
		var count = 0;
		for( item in this.data ) {
			var s = new Stub( new Rectangle(0,0,65,70), item.imgData, 50, item.selected, item.name );
			stubStrip.addChild(s);
			s.x = 68 * count;
			s.y = imgY;
			s.addEventListener( MouseEvent.CLICK, function(_) me.toggleItem( item.id ) );
			stubs.push(s);
			count++;
		}
		
		scrollStep = imageScrollStep = 68.;
		var total = 68.0 * count;
		if( total > bounds.width )
			total -= 3;
		minScrollX = -total + bounds.width;
		
		leftButton.addEventListener( MouseEvent.MOUSE_DOWN, onScrollLeftDown );
		rightButton.addEventListener( MouseEvent.MOUSE_DOWN, onScrollRightDown );
		leftButton.addEventListener( MouseEvent.MOUSE_UP, onScrollLeftUp );
		rightButton.addEventListener( MouseEvent.MOUSE_UP, onScrollRightUp );
		
		stubStrip.visible = true;
	}
	
	var scrollDirection : String;
	var scrollStep : Float;
	var scrollTimer : Dynamic;
	var ctInterval:Dynamic;
	var scrollContinuous : Bool;
	
	function onScrollLeft() {
		stubStrip.x = 1.0 * Math.min( 0, stubStrip.x + scrollStep );
	}
	
	function onScrollRight() {
		stubStrip.x = 1.0 * Math.max( minScrollX, stubStrip.x - scrollStep );
	}
	
	function setContinuousScroll() {
		var me = this;
		untyped window.clearInterval( me.ctInterval );
		scrollContinuous = true;
		scrollStep = 26;//imageScrollStep / 3;
		//scrollTimer = new Timer( 100 );
		scrollTimer = untyped window.setInterval( function() {
			if( me.scrollDirection == "right" )
				me.onScrollRight();
			else
				me.onScrollLeft();
		}, 100);
	}
	
	function scrollDown() {
		if( scrollTimer != null )
			//scrollTimer.stop();
			untyped window.clearInterval( scrollTimer );
		//scrollTimer = Timer.delay( setContinuousScroll, 200 );
		if (ctInterval != null)
		ctInterval = untyped window.setInterval( setContinuousScroll, 200);
		scrollContinuous = false;
		scrollStep = imageScrollStep;
	}
	
	function onScrollLeftDown(_) {
		scrollDown();
		scrollDirection = "left";
	}
	
	function onScrollRightDown(_) {
		scrollDown();
		scrollDirection = "right";
	}
	
	function onScrollLeftUp(_) {
		//scrollTimer.stop();
		untyped window.clearInterval( scrollTimer );
		if( !scrollContinuous )
			onScrollLeft();
	}
	
	function onScrollRightUp(_) {
		//scrollTimer.stop();
		untyped window.clearInterval( scrollTimer );
		if( !scrollContinuous )
			onScrollRight();
	}
	
	public function selectIndex( index : Int, selected : Bool ) {
		stubs[index].setSelected( selected );
	}
}

class Stub extends Sprite {
	
	var bitmap : Bitmap;
	var bar : Sprite;
	var title : TextField;
	var bounds : Rectangle;
	var bkg : Sprite;
	
	public var selected : Bool;
	
	public function new( bounds : Rectangle, data : BitmapData, imgH : Float, selected : Bool, name : String ) {
		
		super();
		
		this.bounds = bounds;
		
		addChild( bitmap = new Bitmap(data) );
		addChild( bar = new Sprite() );
		addChild( title = new TextField() );
		addChild( bkg = new Sprite() );
		
		bitmap.width = bounds.width;
		bitmap.height = imgH;
		
		DrawUtil.drawRect( bar, bounds.x, bounds.y + imgH, bounds.width, 3, 0x555555, 1.0 );
		
		DrawUtil.drawRect( bkg, bounds.x, bounds.y, bounds.width, bounds.height, 0x555555, 0.0 );
		
		var fmt = new TextFormat( "Arial" );
		fmt.align = TextFormatAlign.CENTER;
		fmt.color = 0x323232;
		fmt.size = 12;
		
		title.defaultTextFormat = fmt;
		title.selectable = false;
		title.x = bounds.x - 2;
		title.y = bounds.y + imgH + 4;
		title.width = bounds.width + 4;
		title.height = bounds.height - imgH;
		title.text = name;
		title.correct();
		
		setSelected(selected);
	}
	
	public function toggle() {
		setSelected( !selected );
	}
	
	public function setSelected( selected_ : Bool ) {
		selected = selected_;
		bar.alpha = selected ? 1.0 : 0.0;
	}
	
}

class ScrollButton extends Sprite {
	
	var bkg : Sprite;
	var icon : Sprite;
	var field : TextField;
	var text : String;
	var orientation : Orientation;
	
	public function new( text : String, orientation : Orientation ) {
		
		super();
		
		this.text = text;
		this.orientation = orientation;
		var labelW = 65;
		var w = 82;
		
		addChild( icon = new Sprite() );
		addChild( field = new TextField() );
		addChild( bkg = new Sprite() ); // use as cover instead
		
		DrawUtil.drawRect( bkg, 0, 0, w, 18, 0xffffff, 0.0 );
		
		var fmt = new TextFormat( "Arial" );
		fmt.align = switch( orientation ) { case l: TextFormatAlign.LEFT; case r: TextFormatAlign.RIGHT; default: null; };
		fmt.color = 0x58585A;
		fmt.size = 12;
		
		field.defaultTextFormat = fmt;
		field.selectable = false;
		field.x = switch( orientation ) { case l: w - labelW; default: #if js -2 #else 0 #end; };
		field.y = -1;
		field.width = labelW;
		field.height = 18;
		field.text = text;
		field.correct();
		
		draw();
		
		icon.x = switch( orientation ) { case r: 1.0 * w - 13; default: 3; };
		icon.y = 3;
	}
	
	public function draw() {
		icon.graphics.clear();
		icon = DrawUtil.drawTriangle( icon, 0, 0, 11, 9, 11, orientation, 0x008000, 1.0 );
	}
}
