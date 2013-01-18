package browser.system;
#if js


class ApplicationDomain {
	
	
	public static var currentDomain:ApplicationDomain = this;
	
	
	public function new(parentDomain:ApplicationDomain = null) {
		
		
		
	}
	
	
	public function getDefinition(name:String) {
		
		return Type.getClass(Type.getClassName(name));
		
	}
	
	
	public function hasDefinition(name:String) {
		
		return Type.getClass(Type.getClassName(name)) != null;
		
	}
	
	
}


#end