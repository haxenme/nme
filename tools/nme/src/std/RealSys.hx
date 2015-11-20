package std;
class RealSys extends SysProxy {

    override public function println(v:Dynamic):Void {
        Sys.println(v);
    }

    override public function args():Array<String> {
        return Sys.args();
    }
}