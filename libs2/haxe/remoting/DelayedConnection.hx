/*
 * Copyright (c) 2005-2008, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package haxe.remoting;

/**
 * Delay messages until an Async connection is ready
 * <pre>
 * dc = DelayedConnection.create();
 * ... later after the AsyncConnection is ready
 * dc.connection = myAsycConnection;
 * 
 */
class DelayedConnection implements AsyncConnection, implements Dynamic<AsyncConnection> {
	/** Once set, the calls queued will all be processed */
	public var connection(getConnection,setConnection) : AsyncConnection;

	var __path : Array<String>;
	var __data : {
		cnx : AsyncConnection,
		error : Dynamic -> Void,
		cache : Array<{
			path : Array<String>,
			params : Array<Dynamic>,
			onResult : Dynamic -> Void,
			onError : Dynamic -> Void
		}>,
	};

	function new(data, path : Array<String>) {
		__data = data;
		__path = path;
	}

	public function setErrorHandler(h) {
		__data.error = h;
	}

	public function resolve( name ) : AsyncConnection {
		var d = new DelayedConnection(__data,__path.copy());
		d.__path.push(name);
		return d;
	}

	function getConnection() {
		return __data.cnx;
	}

	/**
	 * Once set, the calls queued will all be processed
	 * @param	cnx
	 */
	function setConnection(cnx : AsyncConnection) : AsyncConnection {
		__data.cnx = cnx;
		process(this);
		return cnx;
	}

	public function call( params : Array<Dynamic>, ?onResult ) {
		__data.cache.push({ path : __path, params : params, onResult : onResult, onError : __data.error });
		process(this);
	}

	static function process( d : DelayedConnection ) {
		var cnx = d.__data.cnx;
		if( cnx == null )
			return;
		while( true ) {
			var m = d.__data.cache.shift();
			if( m == null )
				break;
			var c = cnx;
			for( p in m.path )
				c = c.resolve(p);
			c.setErrorHandler(m.onError);
			c.call(m.params,m.onResult);
		}
	}

	public static function create() {
		return new DelayedConnection({ cnx : null, error : function(e) throw e, cache : new Array() },[]);
	}

}
