package;

class CommandLineToolsLauncher 
{
    public static function main():Void {
        Sys.exit(Sys.command('./bin/tools/${calcBinName()}', Sys.args()));
    }

    static function calcBinName():String {
        var name:String = 'CommandLineTools';
        #if debug
        name+='-debug';
        #end
        if(Sys.systemName() == "Windows")
            name+='.exe';
        return name;
    }
}