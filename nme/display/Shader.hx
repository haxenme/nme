package nme.display;

import nme.Loader;

class Shader
{
	/** @private */ public var nmeHandle:Dynamic;

	public function new(inVertSource:String, inFragSource:String)
	{
		nmeHandle = nme_shader_create(inVertSource, inFragSource);
	}

	public function setUniformValue(name:String, value:Dynamic)
	{
		nme_shader_set_uniform(nmeHandle, name, value);
	}

	private static var nme_shader_create = Loader.load("nme_shader_create", 2);
	private static var nme_shader_set_uniform = Loader.load("nme_shader_set_uniform", 3);
}