class Keystore {
	
	public var alias:String;
	public var aliasPassword:String;
	public var password:String;
	public var path:String;
	public var type:String;
	
	public function new (path:String, password:String = null, alias:String = "", aliasPassword:String = null) {
		
		this.path = path;
		this.password = password;
		this.alias = alias;
		this.aliasPassword = aliasPassword;
		
	}
	
}