package fr.hyperfiction.utils;

/**
 * ...
 * @author shoe[box]
 */

class URLVarsParser{

	// -------o constructor
		
		/**
		* constructor
		*
		* @param	
		* @return	void
		*/
		private function new() {
			
		}
	
	// -------o public
				
		/**
		* 
		* 
		* @public
		* @return	void
		*/
		static public function parse( s : String , ?h : Hash<String> ) : Hash<String> {
			
			if( h == null )
				h = new Hash<String>( );
			else 
				for( k in h.keys( ) )
					h.remove( k );

			var r : EReg = ~/^(.+)=(.+)/;
			var a = s.split( "&" );

			for( l in a ){

				if( !r.match( l ) )	
					continue;		
				
				h.set( r.matched( 1 ) , r.matched( 2 ) );
			}

			return h;
		}	

	// -------o protected
	
		

	// -------o misc
	
}