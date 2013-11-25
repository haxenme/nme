package io.nme.samples.nyancat;


import nme.display.Sprite;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.Assets;


class NyanCat extends Sprite {
	
	
	public function new () {
		
		super ();
		
		var cat = Assets.getMovieClip ("library:NyanCatAnimation");
		addChild (cat);
		
		//var theme = Assets.getSound ("assets/Nyan Cat Theme.mp3");
		//theme.play (0, -1);
		
	}
	
	
}