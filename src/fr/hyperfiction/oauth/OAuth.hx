package fr.hyperfiction.oauth;

import chx.hash.HMAC;
import chx.hash.Sha1;
import haxe.crypto.BaseCode;
import haxe.Http;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;

/**
 * ...
 * @author shoe[box]
 */

class OAuth{

	public var consumerKey		( default , set ) : String;
	public var consumerSecret	( default , default ) : String;
	public var baseURL			( default , default ) : String;
	public var token			( default , default ) : String;
	public var tokenSecret		( default , default ) : String;

	private var _encoder	: HMAC;
	private var _hParams	: Map<String,String>;
	private var _loader		: URLLoader;
	private var _oParams	: Params;

	private static var NONCE_CHARS : Array<String> = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");

	// -------o constructor

		/**
		* constructor
		*
		* @param
		* @return	void
		*/
		public function new( ) {
			trace("constructor");
			_encoder = new HMAC( new Sha1( ) );
			_oParams = new Params( );
		}

	// -------o public

	// -------o protected

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _getFormated_params_to_urlvars( hParams : Map<String,String> ) : URLVariables{
			var v = new URLVariables( );
			for( k in hParams.keys( ) )
				Reflect.setField( v , k , hParams.get( k ) );

			return v;
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _requestAccessToken( ) : Void{


			var sURL = "https://api.twitter.com/1.1/statuses/update.json";

			var req = _getSigned_request(GET,sURL );

			var r = new URLRequest( sURL );
				r.url = sURL+"?include_entities=true";
				#if !display
				r.requestHeaders = [ new URLRequestHeader("Authorization",req) ];
				#end
				r.method = flash.net.URLRequestMethod.POST;
				//r.data = v;

			var l = new URLLoader( );
				l.addEventListener( Event.COMPLETE , function( e ){
					trace( e.target.data );
				} );
				l.addEventListener( flash.events.IOErrorEvent.IO_ERROR, function( io ){
					trace( io );
				});
				l.addEventListener( flash.events.SecurityErrorEvent.SECURITY_ERROR, function( s ){
					trace( s );
				});
				l.load( r );

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _getSigned_request( method:  Methods , sURL : String , ?aRequestParams : Params , ?aBodyParams : Params ) : String{
			//trace("_getSigned_request ::: "+method+" - "+sURL+" - "+aRequestParams);

			//
				var aBase : Array<Value> = [ ];
					aBase.push( { name:"oauth_nonce"				,value:_generateNonce_string()});
					aBase.push( { name:"oauth_signature_method"		,value:"HMAC-SHA1"});
					aBase.push( { name:"oauth_consumer_key"			,value:consumerKey});
					aBase.push( { name:"oauth_timestamp"			,value:_getTimestamp( )});
					aBase.push( { name:"oauth_version"				,value:"1.0"});
					if( token != null && token != "" )
					aBase.push( { name:"oauth_token",value:token});
					aBase.sort( _sort );


			//
				if( aRequestParams != null )
					for( p in aRequestParams.get( ) )
						aBase.push( { name : p.name , value : p.value} );
				aBase.sort( _sort );


			//
				var a = aBase.slice( 0 , aBase.length );

			//
				var sParams = "";
				var iter = a.iterator( );
				for( v in iter ){
					trace( v.name+" = "+v.value);
					sParams += uriEncode( v.name )+"="+uriEncode( v.value )+( iter.hasNext( ) ? "&" : "" );
				}



			//
				var sParams_and_args = sParams.substr( 0 );
				if( aBodyParams != null )
					sParams_and_args += "&"+aBodyParams.toString( );
				trace( sParams_and_args );

			//
				var sSign = Std.string( method )+"&";

				//URL
					sSign += uriEncode( sURL )+"&";

				//Params
					sSign += uriEncode( sParams_and_args );

				#if debug
				trace("OAUTH Signature : ");
				trace( sSign );
				#end

			//Key
				var sKey = uriEncode( consumerSecret ) + "&"+uriEncode( tokenSecret );
				trace("sKey ::: "+sKey);
				var hashed = _encoder.calculate( Bytes.ofString( sKey ) , Bytes.ofString( sSign ) );
				trace( hashed.toString( ) );
				var signature = encode( hashed );
				trace( signature );

			//Ajout de la signature
				aBase.push( { name:"oauth_signature" , value : signature } );
				aBase.sort( _sort );

			//Res
				//trace("res-----------------------");
				var s = "OAuth ";
				var i = 0;
				for( v in aBase ) {

					//trace( v );

					if( i++ > 0 )
						s += ", ";

					s+= uriEncode( v.name ); //%encode key
					s+= '="';
					s+= uriEncode( v.value );
					s+= '"';

				}

			return s;

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _sort( v1 : Value , v2 : Value ) : Int{
			var a = v1.name.toLowerCase();
		    var b = v2.name.toLowerCase();
		    if (a < b) return -1;
		    if (a > b) return 1;
		    return 0;
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		static public function uriEncode( s : String , ?b : Bool ) : String{

			var regex : EReg = ~/[a-zA-Z0-9_~\.\-]/;
			var c;
			var res = "";
			for( i in 0...s.length ){
				c = s.charAt( i );
				if( regex.match( c )){
					res += c;
					continue;
				}else if( ( b && c == " " ) ){
					res += "+";
					continue;
				}
				//trace( c+"\t-\t"+regex.match( c )+"-"+StringTools.hex(c.charCodeAt( 0 )).toUpperCase( ) );
				res += "%"+StringTools.hex(c.charCodeAt( 0 )).toUpperCase( );
			}



			return res;

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _getKey( ) : Bytes{
			return Bytes.ofString( StringTools.urlEncode( consumerSecret ) + "&"+tokenSecret );
		}


		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _generateNonce_string( ) : String{
			//return "ea9ec8429b68d6b77cd5600adbbb0456";
			var res : String = "";
			for( i in 0...20 )
				res += NONCE_CHARS[ Std.int( Math.random( ) * NONCE_CHARS.length ) ];

			return res;
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _getTimestamp( ) : String {
			//return "1318467427";
			return Std.int( Date.now( ).getTime( ) / 1000 )+"";
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function set_consumerKey( s : String ) : String{
			trace("_setConsumer_key ::: "+s);
			return this.consumerKey = s;
		}

		/**
		* Encodes any bytes buffer to base64
		*
		* @param bytes Buffer to encode
		* @return Base64 encoded string
		**/
		inline private static function encode(bytes : Bytes) : String {
			var ext : String = switch (bytes.length % 3) {
			case 1: "==";
			case 2: "=";
			case 0: "";
			case _:"";
			}
			var enc = new BaseCode( haxe.io.Bytes.ofString(Constants.DIGITS_BASE64));
			return enc.encodeBytes( haxe.io.Bytes.ofData( bytes.getData( ))).toString() + ext;
		}

	// -------o misc

}


enum Methods{
	POST;
	GET;
}

enum Requests{
	REQUEST_TOKEN( s : String , sURL : String );
	ACCESS_TOKEN( sURL : String , sToken : String , sVerifier : String );
	REQUEST( m : Methods , s : String , ?aReq : Params , ?aBody : Params );
	ACCESS;
}

/**
 * ...
 * @author shoe[box]
 */

class Params{

	private var _aParams : Array<Value>;

	// -------o constructor

		/**
		* constructor
		*
		* @param
		* @return	void
		*/
		public function new( ?name : String , ?value : String ) {
			_aParams = [ ];
			if( name != null && value != null )
				_aParams.push( { name: name , value : value} );
		}

	// -------o public

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function get( ) : Array<Value>{
			return _aParams;
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function set( key : String , value : String ) : Void {
			_aParams.push( { name : key , value : value } );
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function toString( ) : String {

			var res = "";
			var iter = _aParams.iterator( );
			for( val in iter )
				res += OAuth.uriEncode( val.name )+"="+OAuth.uriEncode( val.value )+( iter.hasNext( ) ? "&":"" );
			return res;

			//OAuth.uriEncode

		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function getVars( ?res : URLVariables ) : URLVariables {

			if( res == null )
				res = new URLVariables( );

			for( p in _aParams )
				Reflect.setField( res , p.name , p.value );

			return res;

		}

	// -------o protected



	// -------o misc

}


typedef Value={
	public var name : String;
	public var value : String;
}