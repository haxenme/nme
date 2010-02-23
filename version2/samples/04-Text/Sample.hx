import nme.Lib;


class Sample
{
	public function new()
	{
		var tf = new nme.text.TextField();
		tf.type = nme.text.TextFieldType.INPUT;
		tf.text = "Hello Hello Hello, what's all this here then?";
		tf.background = true;
		tf.backgroundColor = 0xccccff;
		tf.border = true;
		tf.borderColor = 0x000000;
		tf.x = 100;
		tf.y = 100;
		nme.Lib.current.addChild(tf);
	}

	public static function main()
	{
	#if flash
		new Sample();
	#else
		Lib.init(320,480,60,0xffffff,(0*Lib.HARDWARE) | Lib.RESIZABLE);

		new Sample();

		Lib.mainLoop();
	#end
	}

}
