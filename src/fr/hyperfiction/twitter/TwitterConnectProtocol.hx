package fr.hyperfiction.twitter;

import fr.hyperfiction.twitter.HypTwitter;
import fr.hyperfiction.utils.URLVarsParser;

import flash.net.URLVariables;

/**
 * ...
 * @author shoe[box]
 */
@:build( ShortCuts.mirrors( ) )
class TwitterConnectProtocol{

	public var sCallBack_url( default , default ) : String;

	private var _fAskPin			: Void->Void;
	private var _fConnected			: Void->Void;
	private var _fOnError			: String->Void;
	private var _hTemp				: Map<String,String>;
	private var _oTwitter_instance	: HypTwitter;
	private var _sAuthToken			: String;

	private static inline var AUTHENTIFICATE : String = "https://api.twitter.com/oauth/authenticate?oauth_token=";

	// -------o constructor

		/**
		* constructor
		*
		* @param
		* @return	void
		*/
		public function new( onConnected : Void->Void , onError : String->Void , ?fAskPin : Void->Void ) {
			sCallBack_url	= "osef";
			_fAskPin	= fAskPin;
			_fConnected	= onConnected;
			_fOnError	= onError;
			_hTemp		= new Map<String,String>( );
		}

	// -------o public

		/**
		* Perform the three step authentification protocol
		*
		* @public
		* @return	void
		*/
		public function connect( oTwitter_instance : HypTwitter ) : Void {
			trace("connect");
			_oTwitter_instance = oTwitter_instance;
			_phase1( );
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function verify( sPin : String ) : Void {
			trace("verifiy ::: "+sPin);
			_phase3( _sAuthToken , sPin );
		}

	// -------o protected

		/**
		* Phase 1 of the Twitter connect protocol
		*
		* @private
		* @return	void
		*/
		private function _phase1( ) : Void{
			_oTwitter_instance.token = "";
			trace("_phase1");
			_oTwitter_instance.onDatas = _onPhase1_response;

			#if ( mobile )

				#if android
				_oTwitter_instance.call( REQUEST_TOKEN( "app://twitter" ) );
				#end

				#if ios
				trace("ios");
				_oTwitter_instance.call( REQUEST_REVERSE_TOKEN );
				_oTwitter_instance.onDatas = _onPhase1_iPhone_response;
				#end

			#else
				_oTwitter_instance.call( REQUEST_TOKEN( "http://localhost/sign-in-with-twitter/" ) );
			#end
		}

		/**
		* Phase 1 response
		*
		* @private
		* @return	void
		*/
		private function _onPhase1_response( s : String ) : Void{
			trace("_onPhase1_response ::: "+s);

			//
				_hTemp = URLVarsParser.parse( s , _hTemp );

			//
				var bConfirmed			= _hTemp.get( "oauth_callback_confirmed" ) == "true";
				var sAuth_token_secret	= _hTemp.get( "oauth_token_secret" );
				_sAuthToken				= _hTemp.get( "oauth_token" );

				trace("bConfirmed         ::: "+bConfirmed);
				trace("sAuth_token_secret ::: "+sAuth_token_secret);
				trace("_sAuthToken        ::: "+_sAuthToken);

				if( !bConfirmed )
					trace("confirmation error");

			//
				_phase2( _sAuthToken );
		}

		/**
		* Phase 2 launch
		*
		* @private
		* @return	void
		*/
		private function _phase2( sAuth_token : String ) : Void{
			trace("_phase2 ::: "+sAuth_token);

			#if android

				flash.Lib.getURL( new flash.net.URLRequest( AUTHENTIFICATE+sAuth_token ) );
				HypTwitter_set_callback( _onIntent );

			#else

				//For non-mobile device we ask the PIN
				flash.Lib.getURL( new flash.net.URLRequest( AUTHENTIFICATE+sAuth_token ) );
				_fAskPin( );

			#end
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _phaseResponse2( sResponse : String ) : Void{
			trace("_phaseResponse2 ::: "+sResponse);

			//
				_hTemp = URLVarsParser.parse( sResponse , _hTemp );

			//
				var sOauth_token	= _hTemp.get( "oauth_token" );
				var sOauth_verifier	= _hTemp.get( "oauth_verifier" );
				trace("sOauth_token    ::: "+sOauth_token);
				trace("sOauth_verifier ::: "+sOauth_verifier);

			//
				_phase3( sOauth_token , sOauth_verifier );

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _phase3( sOauth_token : String , sOauth_verifier : String ) : Void{
			_oTwitter_instance.onDatas = _onPhase3_response;
			_oTwitter_instance.call( ACCESS_TOKEN( sOauth_token , sOauth_verifier ) );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _onPhase3_response( s : String ) : Void{
			trace("_onPhase3_response ::: "+s);
			_parseResponse( s );
			_fConnected( );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _parseResponse( s : String ) : Void{

			trace( s );

			//
				var res = URLVarsParser.parse( s );
				_oTwitter_instance.token		= res.get( "oauth_token" );
				_oTwitter_instance.tokenSecret	= res.get( "oauth_token_secret" );
				trace( res );

			//
				trace( "tokenSecret	::: " + _oTwitter_instance.tokenSecret );
				trace( "token 		::: " + _oTwitter_instance.token );

			//
				#if android
				var bOk	= Reflect.field( res , "oauth_callback_confirmed" );
				trace( "bOk ::: " + bOk );
				#end
		}

	// -------o misc

	// -------o ios

		#if ios

		private static inline var CONNECTION_OK		: String = "OK";
		private static inline var CONNECTION_ERROR	: String = "ERROR";

		/**
		*
		*
		* @private
		* @return	void
		*/
		@CPP("HypTwitter")
		static private function HypTwitter_connect( sConsumerKey : String , sAuthParam : String ) : Void{

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		@CPP("HypTwitter")
		private function HypTwitter_set_reverse_auth_callback( cb : String->String->Void ) : Void{
		}

		/**
		* Calling the IOS reverse auth mode
		*
		* @private
		* @return	void
		*/
		private function _onPhase1_iPhone_response( s : String ) : Void{
			trace("_onPhase1_iPhone_response ::: "+s);
				HypTwitter_set_reverse_auth_callback( _onIOS_callback );
				HypTwitter_connect( _oTwitter_instance.consumerKey , s );
		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _onIOS_callback( s : String , sArg : String ) : Void{

			if( s == null )
				return;

			//trace("_onIOS_callback ::: "+s+" - "+sArg);
			switch( s ){

				case CONNECTION_OK:
					_parseResponse( sArg );
					_fConnected( );

				case CONNECTION_ERROR:
					_fOnError( sArg );
			}
		}


		#end

	// -------o android

		#if android

		/**
		*
		*
		* @public
		* @return	void
		*/
		@CPP("HypTwitter")
		public function HypTwitter_set_callback( s : String->Void ) : Void {

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _onIntent( sIntent : String ) : Void{
			trace("_onIntent ::: "+sIntent);
			_phaseResponse2( sIntent );
		}

		#end

}