package native.display;

import nme.events.EventDispatcher;
import nme.events.Event;
import nme.events.ErrorEvent;
import native.display3D.Context3D;

class Stage3D extends EventDispatcher{

    public var context3D : Context3D;

    public function new() {
        super();
    }

    public function requestContext3D() : Void{
        context3D = new Context3D();
        dispatchEvent(new Event(Event.CONTEXT3D_CREATE));

        // TODO ErrorEvent ?
    }
}
