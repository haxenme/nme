package nme.display;

class ManagedStage extends Stage
{
	public function new(inWidth:Int,inHeight:Int)
	{
	   super(nme_managed_stage_create(inWidth,inHeight),inWidth,inHeight);
	}

   public function resize(inWidth:Int,inHeight:Int)
	{
	   nme_managed_stage_resize(nmeHandle,inWidth,inHeight);
	}

   override public function nmeRender(inSendEnterFrame:Bool)
   {
	   beginRender();
      super.nmeRender(inSendEnterFrame);
		endRender();
   }

	override function nmeDoProcessStageEvent(inEvent:Dynamic) : Float
	{
	   nmePollTimers();
      var wake = super.nmeDoProcessStageEvent(inEvent);
		setNextWake(wake);
		return wake;
	}

	dynamic public function setNextWake(inDelay:Float) { }
	dynamic public function beginRender() { }
	dynamic public function endRender() { }

	static var nme_managed_stage_create = nme.Loader.load("nme_managed_stage_create",2);
	static var nme_managed_stage_resize = nme.Loader.load("nme_managed_stage_resize",3);
}
