package;

class CommandLineToolsLauncher 
{
    public static function main():Void {
        Sys.command('./bin/tools/${calcBinName()}', Sys.args());
    }

    static function calcBinName():String {
        #if windows
        return 'CommandLineTools-debug.exe';
        #else
        return 'CommandLineTools-debug';
        #end
    }
}