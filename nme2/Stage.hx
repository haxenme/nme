package nme2;

class Stage
{
	var mHandle:Dynamic;

	public var onKey: Int -> Bool -> Int -> Int ->Void; 
	public var onMouseMove: Int -> Int ->Void; 
	public var onMouseButton: Int -> Int -> Int -> Bool -> Int ->Void; 
	public var onResize: Int -> Int ->Void; 
	public var onRender: Void ->Void; 
	public var onQuit: Void ->Void; 


	public function new(inHandle:Dynamic)
	{
	   mHandle = inHandle;

		var set_stage_handler = nme.Loader.load("nme_set_stage_handler",2);
		set_stage_handler(mHandle,processStageEvent);
	}

	function processStageEvent(inEvent:Dynamic) : Dynamic
	{
		// TODO: timer event?
		Manager.pollTimers();
		switch(Std.int(Reflect.field( inEvent, "type" ) ) )
		{
			case 1: // KEY
				if (onKey!=null)
					untyped onKey(inEvent.code, inEvent.down, inEvent.char, inEvent.flags );

			case 2: // MOUSE_MOVE
				if (onMouseMove!=null)
					untyped onMouseMove(inEvent.x, inEvent.y );

			case 3: // MOUSE_BUTTON
				if (onMouseButton!=null)
					untyped onMouseButton(inEvent.button, inEvent.x, inEvent.y, inEvent.down, inEvent.flags);
			case 4: // RESIZE
				if (onResize!=null)
					untyped onResize(inEvent.x, inEvent.y);

			case 5: // RENDER
				if (onRender!=null)
					untyped onRender();

			case 6: // QUIT
				if (onQuit!=null)
					untyped onQuit();

			// TODO: user, sys_wm, sound_finished
		}

		return null;
	}


}
