package nme.script;

interface IScriptHandler
{
   public function scriptLog(inMessage:String) : Void;
   public function scriptRunSync(f:Void->Void) : Void;
}

