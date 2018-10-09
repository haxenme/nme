package nme.display3D;
import nme.geom.Rectangle;
import nme.display3D.Context3D;

@:nativeProperty
class Context3DUtils {

    /**
    * Common API for both cpp and flash to set the render callback
    **/
    inline static public function setRenderCallback(context3D : Context3D, func : Void -> Void) : Void{
        function render(rect : Dynamic):Void{func();}
        #if flash
        nme.Lib.current.addEventListener(nme.events.Event.ENTER_FRAME, render);
        #elseif (!flash || js)
        context3D.setRenderMethod(render);
        #end
    }
}

