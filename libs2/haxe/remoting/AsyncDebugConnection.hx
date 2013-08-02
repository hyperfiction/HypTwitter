/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * AsyncConnection that allows for logging
 */
class AsyncDebugConnection implements AsyncConnection, implements Dynamic<AsyncDebugConnection> {

	var __path : Array<String>;
	var __cnx : AsyncConnection;
	var __data : {
		error : Dynamic -> Void,
		oncall : Array<String> -> Array<Dynamic> -> Void,
		onerror : Array<String> -> Array<Dynamic> -> Dynamic -> Void,
		onresult : Array<String> -> Array<Dynamic> -> Dynamic -> Void,
	};

	function new(path : Array<String>, cnx : AsyncConnection, handlers) {
		__path = path;
		__cnx = cnx;
		__data = handlers;
	}

	public function resolve( name ) : AsyncConnection {
		var cnx = new AsyncDebugConnection(__path.copy(),__cnx.resolve(name),__data);
		cnx.__path.push(name);
		return cnx;
	}

	public function setErrorHandler(h: Dynamic -> Void) {
		__data.error = h;
	}

	public function setErrorDebug(h: Array<String> -> Array<Dynamic> -> Dynamic -> Void) {
		__data.onerror = h;
	}

	public function setResultDebug(h: Array<String> -> Array<Dynamic> -> Dynamic -> Void) {
		__data.onresult = h;
	}

	public function setCallDebug(h: Array<String> -> Array<Dynamic> -> Void) {
		__data.oncall = h;
	}

	public function call( params : Array<Dynamic>, ?onResult : Dynamic -> Void ) {
		var me = this;
		__data.oncall(__path,params);
		__cnx.setErrorHandler(function(e) {
			me.__data.onerror(me.__path,params,e);
			me.__data.error(e);
		});
		__cnx.call(params,function(r) {
			me.__data.onresult(me.__path,params,r);
			if( onResult != null ) onResult(r);
		});
	}

	/**
	 * Creates a AsyncDebugConnection. Once created, use set* methods]
	 * to add event handlers.
	 * @param	cnx an existing AsyncConnection
	 * @return New debug connection wrapping the AsyncConnection
	 */
	public static function create( cnx : AsyncConnection ) : AsyncDebugConnection {
		var cnx = new AsyncDebugConnection([],cnx,{
			error : function(e) throw e,
			oncall : function(path,params) {},
			onerror : null,
			onresult : null,
		});
		cnx.setErrorDebug(function(path,params,e) trace(path.join(".")+"("+params.join(",")+") = ERROR "+Std.string(e)));
		cnx.setResultDebug(function(path,params,e) trace(path.join(".")+"("+params.join(",")+") = "+Std.string(e)));
		return cnx;
	}

}
