package std;
class MockSys extends SysProxy {

    public var arguments:Array<String>;

    public function new():Void {
        super();
        arguments = [];
    }

    override public function println(v:Dynamic):Void {
    }

    override public function args():Array<String> {
        return arguments;
    }
}