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
package chx.sys.db;

import chx.sys.db.Connection;

#if neko
private class D {

	static function load(fun,args) : Dynamic {
		return chx.Lib.load(lib,fun,args);
	}

	static var lib = try { chx.Lib.load("mysql5","connect",1); "mysql5"; } catch( e : Dynamic ) "mysql";
	public static var connect = load("connect",1);
	public static var select_db = load("select_db",2);
	public static var request = load("request",2);
	public static var close = load("close",1);
	public static var escape = load("escape",2);
	public static var result_get_length = load("result_get_length",1);
	public static var result_get_nfields = load("result_get_nfields",1);
	public static var result_next = load("result_next",1);
	public static var result_get = load("result_get",2);
	public static var result_get_int = load("result_get_int",2);
	public static var result_get_float = load("result_get_float",2);
	public static var result_set_conv_date = load("result_set_conv_date",2);

}

private class MysqlResultSet implements ResultSet {

	public var length(getLength,null) : Int;
	public var nfields(getNFields,null) : Int;
	private var __r : Void;
	private var cache : Dynamic;

	public function new(r) {
		__r = r;
	}

	private function getLength() {
		return D.result_get_length(__r);
	}

	private function getNFields() {
		return D.result_get_nfields(__r);
	}

	public function hasNext() {
		if( cache == null )
			cache = next();
		return (cache != null);
	}

	public function next() : Dynamic {
		var c = cache;
		if( c != null ) {
			cache = null;
			return c;
		}
		c = D.result_next(__r);
		if( c == null )
			return null;
		untyped {
			var f = __dollar__objfields(c);
			var i = 0;
			var l = __dollar__asize(f);
			while( i < l ) {
				var v = __dollar__objget(c,f[i]);
				if( __dollar__typeof(v) == __dollar__tstring )
					__dollar__objset(c,f[i],new String(v));
				i = i + 1;
			}
		}
		return c;
	}

	public function results() : List<Dynamic> {
		var l = new List();
		while( hasNext() )
			l.add(next());
		return l;
	}

	public function getResult( n : Int ) {
		return new String(D.result_get(__r,n));
	}

	public function getIntResult( n : Int ) : Int {
		return D.result_get_int(__r,n);
	}

	public function getFloatResult( n : Int ) : Float {
		return D.result_get_float(__r,n);
	}

}

private class MysqlConnection implements Connection {

	private var __c : Void;

	public function new(c) {
		__c = c;
	}

	public function request( s : String ) : ResultSet {
		try {
			var r = D.request(this.__c,untyped s.__s);
			D.result_set_conv_date(r,function(d) { return untyped Date.new1(d); });
			return new MysqlResultSet(r);
		} catch( e : Dynamic ) {
			untyped if( __dollar__typeof(e) == __dollar__tobject && __dollar__typeof(e.msg) == __dollar__tstring )
				e = e.msg;
			untyped __dollar__rethrow(e);
			return null;
		}
	}

	public function close() {
		D.close(__c);
	}

	public function escape( s : String ) {
		return new String(D.escape(__c,untyped s.__s));
	}

	public function quote( s : String ) {
		return "'"+escape(s)+"'";
	}

	public function addValue( s : StringBuf, v : Dynamic ) {
		var t = untyped __dollar__typeof(v);
		if( untyped (t == __dollar__tint || t == __dollar__tnull) )
			s.add(v);
		else if( untyped t == __dollar__tbool )
			s.addChar(if( v ) "1".code else "0".code);
		else {
			s.addChar("'".code);
			s.add(escape(Std.string(v)));
			s.addChar("'".code);
		}
	}

	public function lastInsertId() {
		return request("SELECT LAST_INSERT_ID()").getIntResult(0);
	}

	public function dbName() {
		return "MySQL";
	}

	public function startTransaction() {
		request("START TRANSACTION");
	}

	public function commit() {
		request("COMMIT");
	}

	public function rollback() {
		request("ROLLBACK");
	}

	private static var __use_date = Date;
}

class Mysql {

	public static function connect( params : {
		host : String,
		port : Int,
		user : String,
		pass : String,
		socket : String,
		database : String
	} ) : chx.sys.db.Connection {
		var o = untyped {
			host : params.host.__s,
			port : params.port,
			user : params.user.__s,
			pass : params.pass.__s,
			socket : if( params.socket == null ) null else params.socket.__s
		};
		var c = D.connect(o);
		try {
			D.select_db(c,untyped params.database.__s);
		} catch( e : Dynamic ) {
			D.close(c);
			chx.Lib.rethrow(e);
		}
		return new MysqlConnection(c);
	}

}

#elseif php

private class MysqlConnection implements Connection {

	var c : Void;

	public function new( c : Void) {
		this.c = c;
	}

	public function close() {
		untyped __call__("mysql_close", c);
		untyped __call__("unset", c);
	}

	public function request( s : String ) : ResultSet {
		var h = untyped __call__("mysql_query", s, c);
		if(untyped __physeq__(h, false))
			throw "Error while executing "+s+" ("+untyped __call__("mysql_error", c)+")";
		return new MysqlResultSet(cast h, cast c);
	}

	public function escape( s : String ) {
		return untyped __call__("mysql_real_escape_string", s, c);
	}

	public function quote( s : String ) {
		return "'" + untyped __call__("mysql_real_escape_string", s, c) + "'";
	}

	public function addValue( s : StringBuf, v : Dynamic ) {
		if( untyped __call__("is_int", v) || __call__("is_null", v))
			s.add(v);
		else if( untyped __call__("is_bool", v) )
			s.add(if( v ) 1 else 0);
		else
			s.add(quote(Std.string(v)));
	}

	public function lastInsertId() {
		return untyped __call__("mysql_insert_id", c);
	}

	public function dbName() {
		return "MySQL";
	}

	public function startTransaction() {
		request("START TRANSACTION");
	}

	public function commit() {
		request("COMMIT");
	}

	public function rollback() {
		request("ROLLBACK");
	}
}


private class MysqlResultSet implements ResultSet {
	public var length(getLength,null) : Int;
	public var nfields(getNFields,null) : Int;
	private var __r : Void;
	private var __c : Void;
	private var cache : Dynamic;

	public function new(r, c) {
		__r = r;
		__c = c;
	}

	private function getLength() {
		if(untyped __physeq__(__r, true))
			return untyped __call__("mysql_affected_rows", __c);
		else if (untyped __physeq__(__r, false))
			return 0;
		return untyped __call__("mysql_num_rows", __r);
	}

	private var _nfields : Int;
	private function getNFields() {
		if(_nfields == null)
			_nfields = untyped __call__("mysql_num_fields", __r);
		return _nfields;
	}

	private var _fieldsDesc : Array<Dynamic>;
	private function getFieldsDescription() {
		if(_fieldsDesc == null) {
			_fieldsDesc = [];
			for (i in 0...nfields) {
				var item = {
					name : untyped __call__("mysql_field_name", __r, i),
					type : untyped __call__("mysql_field_type", __r, i)
				};
				_fieldsDesc.push(item);
			}
		}
		return _fieldsDesc;
	}

	private function convert(v : String, type : String) : Dynamic {
		if (v == null) return v;
		switch(type) {
			case "int", "year":
				return untyped __call__("intval", v);
			case "real":
				return untyped __call__("floatval", v);
			case "datetime", "date":
				return Date.fromString(v);
			default:
				return v;
		}
	}

	public function hasNext() {
		if( cache == null )
			cache = next();
		return (cache != null);
	}

	private var cRow : ArrayAccess<String>;
	private function fetchRow() : Bool {
		cRow = untyped __call__("mysql_fetch_array", __r, __php__("MYSQL_NUM"));
		return ! untyped __physeq__(cRow, false);
	}

	public function next() : Dynamic {
		if( cache != null ) {
			var t = cache;
			cache = null;
			return t;
		}
		if(!fetchRow()) return null;

		var o : Dynamic = {};
		var descriptions = getFieldsDescription();
		for(i in 0...nfields)
			Reflect.setField(o, descriptions[i].name, convert(cRow[i], descriptions[i].type));
		return o;
	}

	public function results() : List<Dynamic> {
		var l = new List();
		while( hasNext() )
			l.add(next());
		return l;
	}

	public function getResult( n : Int ) : String {
		if(cRow == null)
			if(!fetchRow())
				return null;
		return cRow[n];
	}

	public function getIntResult( n : Int ) : Int {
		return untyped __call__("intval", getResult(n));
	}

	public function getFloatResult( n : Int ) : Float {
		return untyped __call__("floatval", getResult(n));
	}
}

class Mysql {

	public static function connect( params : {
		host : String,
		port : Int,
		user : String,
		pass : String,
		socket : String,
		database : String
	} ) : chx.sys.db.Connection {
		var c = untyped __call__("mysql_connect",
			params.host + (params.port == null ? '' : ':'+params.port) + (params.socket == null ? '' : ':'+params.socket),
			params.user,
			params.pass);
		if(!untyped __call__("mysql_select_db", params.database, c))
			throw "Unable to connect to " + params.database;
		return new MysqlConnection(c);
	}

}

#end
