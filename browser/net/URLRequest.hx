package browser.net;


class URLRequest {
	
	
	public var contentType:String;
	public var data:Dynamic;
	public var method:String;
	public var requestHeaders:Array<URLRequestHeader>;
	public var url:String;
	
	
	public function new (inURL:String = null) {
		
		if (inURL != null) {
			
			url = inURL;
			
		}
		
		requestHeaders = [];
		method = URLRequestMethod.GET;
		contentType = "application/x-www-form-urlencoded";
		
	}
	
	
}