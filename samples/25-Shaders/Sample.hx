import nme.display.Sprite;
import nme.display.Shader;
import nme.events.Event;

class Sample extends Sprite
{
	public function new()
	{
		super();
		shader = new Shader("uniform mat4 uTransform;
			attribute vec4 aVertex;
			void main() { gl_Position = aVertex * uTransform; }",
			"uniform float uTimer;
			void main() { gl_FragColor = vec4(sin(uTimer), 0, 0, 1); }");

		shader2 = new Shader("uniform mat4 uTransform;
			attribute vec4 aVertex;
			void main() { gl_Position = aVertex * uTransform; }",
			"void main() { gl_FragColor = vec4(1, 1, 0, 1); }");

		// shader.setUniformValue("uVector", [0, 1, 2]);

		graphics.beginFill(0xFFFFFF);
		graphics.drawRect(0, 0, 50, 50);
		graphics.endFill();

		graphics.attachShader(shader);
		graphics.beginFill(0xFFFFFF);
		graphics.drawRect(50, 0, 50, 50);
		graphics.endFill();

		graphics.beginFill(0x0f0f0f);
		graphics.attachShader(shader2);
		graphics.drawRect(100, 0, 50, 50);

		graphics.attachShader(); // detach
		graphics.drawRect(150, 0, 50, 50);
		graphics.endFill();

		startTime = nme.Lib.getTimer();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(e:Event)
	{
		shader.setUniformValue("uTimer", (nme.Lib.getTimer() - startTime) / 1000);
	}

	private var startTime:Int;
	private var shader:Shader;
	private var shader2:Shader;
}