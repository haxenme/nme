package std;
class RealSys extends SysProxy {

    override public function println(v:Dynamic):Void {
        Sys.println(v);
    }
}