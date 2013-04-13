import flash.Lib;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.display.DisplayObject;
import flash.display.IGraphicsData;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.display.StageDisplayState;
import flash.geom.Matrix;

import flash.text.TextField;
import flash.text.TextFormatAlign;



import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.SimpleButton;

class CustomSimpleButton extends SimpleButton {
    private static var upColor:Int   = 0xFFCC00;
    private static var overColor:Int = 0xCCFF00;
    private static var downColor:Int = 0x00CCFF;
    private static var size:Int      = 80;

    public function new() {
        super();
        downState      = new ButtonDisplayState(downColor, size);
        overState      = new ButtonDisplayState(overColor, size);
        upState        = new ButtonDisplayState(upColor, size);
        hitTestState   = new ButtonDisplayState(upColor, size * 2);
        hitTestState.x = -(size / 4);
        hitTestState.y = hitTestState.x;
        useHandCursor  = true;
    }
}

class ButtonDisplayState extends Shape {
    private var bgColor:Int;
    private var size:Int;

    public function new(bgColor:Int, size:Int) {
        super();
        this.bgColor = bgColor;
        this.size    = size;
        draw();
    }

    private function draw():Void {
        graphics.beginFill(bgColor);
        graphics.drawRect(0, 0, size, size);
        graphics.endFill();
    }
}




class Sample extends Sprite
{
public function new()
{
   super();
   Lib.current.addChild(this);

   var but = new CustomSimpleButton();
   but.addEventListener(MouseEvent.MOUSE_DOWN,onButtonDown,false,100);
   Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN,onStageDown);
   
   addChild(but);
}

private function onStageDown(e:MouseEvent):Void
{
	trace("stage received down event.");
}

private function onButtonDown(e:MouseEvent):Void
{
	trace("button received down event: should cancel stage.");
	e.stopPropagation();
	e.stopImmediatePropagation();
}


public static function main()
{
   new Sample();
}

}
