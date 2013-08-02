/*
 * Copyright (c) 2005-2007, The haXe Project Contributors
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
	Build an AsyncConnection from a synchronized Connection.
**/
class AsyncAdapter implements AsyncConnection {

	var __cnx : Connection;
	var __error : { ref : Dynamic -> Void };

	function new(cnx:Connection, error : { ref : Dynamic -> Void }) {
		__cnx = cnx;
		__error = error;
	}

	public function resolve( name ) : AsyncConnection {
		return new AsyncAdapter(__cnx.resolve(name),__error);
	}

	public function setErrorHandler(h : Dynamic -> Void) {
		__error.ref = h;
	}

	public function call( params : Array<Dynamic>, ?onResult : Dynamic -> Void ) {
		var ret;
		try {
			ret = __cnx.call(params);
		} catch( e : Dynamic ) {
			__error.ref(e);
			return;
		}
		if( onResult != null ) onResult(ret);
	}

	public static function create( cnx : Connection ) : AsyncConnection {
		return new AsyncAdapter(cnx,{ ref : function(e) throw e });
	}

}
