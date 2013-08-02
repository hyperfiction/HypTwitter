package fr.hyperfiction.twitter;

import fr.hyperfiction.twitter.TwitterConnectProtocol;
import fr.hyperfiction.oauth.OAuth;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;


/**
 * ...
 * @author shoe[box]
 */

class HypTwitter extends OAuth{

	public var onDatas : String->Void;
	public var onError : String->Void;

	private var _oProtocol_connect	: TwitterConnectProtocol;
	private var _urlRequest			: URLRequest;
	private var _urlLoader			: URLLoader;

	public static inline var ACCOUNT_SETTINGS	: String = "/1.1/account/settings.json";
	public static inline var TIMELINE_USER		: String = "/1.1/statuses/user_timeline.json";
	public static inline var TIMELINE_MENTIONS	: String = "/1.1/statuses/mentions_timeline.json";
	public static inline var TIMELINE_HOME		: String = "/1.1/statuses/home_timeline.json";
	public static inline var TWEET_UPDATE		: String = "/1.1/statuses/update.json";

	// -------o constructor

		/**
		* constructor
		*
		* @param
		* @return	void
		*/
		public function new() {
			super( );
			baseURL	= "https://api.twitter.com";
			_init( );
		}

	// -------o public

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function connect( fOnConnect : Void->Void , fOnError : String->Void , ?fAskPin : Void->Void ) : TwitterConnectProtocol {

			trace("connect");

			//Reset tokens
				token		= "";
				tokenSecret	= "";

			//Connection protocol
			if( _oProtocol_connect == null )
				_oProtocol_connect = new TwitterConnectProtocol( fOnConnect , fOnError , fAskPin );
				_oProtocol_connect.connect( this );

			return _oProtocol_connect;
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function call( req : TwitterRequests ) : Void {
			trace("call ::: "+req);

			var oBodyParams : Params;

			switch( req ){

				case REQUEST( m , sURL , pReqParams , pBodyParams ):
					_call( m , sURL , pReqParams , pBodyParams );

				case REQUEST_TOKEN( sCallBack_url ):
					_call( POST , "/oauth/request_token" , new Params( "oauth_callback" , sCallBack_url), null , false );

				case ACCESS_TOKEN( sToken , sVerifier ):
					token = sToken;
					_call( POST , "/oauth/access_token" , null , new Params( "oauth_verifier" , sVerifier ) , true );

				case REQUEST_REVERSE_TOKEN:
					_call( POST , "/oauth/request_token" , null , new Params( "x_auth_mode" , "reverse_auth" ) , true );
			}
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function verify( ) : Void {

		}

	// -------o protected

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _init( ) : Void{

			_urlLoader = new URLLoader( );
			_urlLoader.addEventListener( Event.COMPLETE , _onLoader_complete );
			_urlLoader.addEventListener( IOErrorEvent.IO_ERROR, _onLoader_ioError );
			_urlLoader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, _onLoader_security_error );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _call( method : Methods , sURL : String , ?pRequest : Params , ?pBody : Params , ?b : Bool = true ) : Void{
			trace("consumerKey ::: "+consumerKey);
			trace("consumerSecret ::: "+consumerSecret);
			var sSignedReq = _getSigned_request( method , baseURL + sURL , pRequest , pBody );
			trace( sSignedReq );
			var req = new URLRequest( baseURL + sURL );
				req.method			= method == POST ? URLRequestMethod.POST : URLRequestMethod.GET;
				#if !display
				req.requestHeaders	= [ new URLRequestHeader("Authorization",sSignedReq) ];
				#end
			if( pRequest != null && b )
				req.url += "?"+pRequest.toString( );

			if( pBody != null )
				req.data = pBody.getVars( );

			_urlLoader.load( req );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _onLoader_complete( e : Event ) : Void{
			if( onDatas != null )
				onDatas( e.target.data );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _onLoader_ioError( e : IOErrorEvent ) : Void{
			trace("_onLoader_ioError ::: "+e);
			if( onError != null )
				onError( "IOERROR "+e.errorID );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _onLoader_security_error( e : SecurityErrorEvent ) : Void{
			trace("_onLoader_security_error ::: "+e);
		}

	// -------o misc

}

enum TwitterRequests{
	REQUEST( method : Methods , sURL : String , ?pReqParams : Params , ?pBodyParams : Params );
	REQUEST_TOKEN( sCallBack_url : String );
	REQUEST_REVERSE_TOKEN;
	ACCESS_TOKEN( sOauth_token : String , sOauth_verifier : String );
}
