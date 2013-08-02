/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
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
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chx.protocols.memedb;

import chx.formats.json.JSONObject;
import chx.formats.json.JSONArray;

/**
	A Result set for a query, much like that in any relational database.
**/
class Result extends JSONDocument {
	// only for debugging.
	static var SAVE_OUTPUT_REQUEST : Bool = false;

	public var rowCount(getRowCount, null) : Null<Int>;
	public var offset(default, null) : Int;
	public var ok(default,null) : Bool;
	/** only available if the view has a reduce function, but is
	also stored as the first row.value **/
	public var value(default,null) : Dynamic;

	private var view : View;
	private var result : Dynamic;
	private var errId : String;
	private var errReason : String;

	private var outputRequest : String;

	public function new(d: Database, v : View, t : Transaction) {
		/**
		Reduced result:
			{"ok":true,"result":491}
		Mapped result:
		{
			"offset":0,
			"total_rows":10,
			"rows":[{"id":"0","key":"0","value":?}, ...]
		}
		**/
		super();
		if(SAVE_OUTPUT_REQUEST)
			this.outputRequest = untyped t.http.requestText;
		this.database = d;
		this.view = v;
		if(!t.isOk()) {
			try {
				this.data = t.getObject();
			}
			catch(e:Dynamic) { this.data = {}; };
			this.errId = optString("error","unknown error");
			this.errReason = optString("reason","unknown error");
			this.ok = false;
			this.rowCount = 0;
			this.offset = 0;
		}
		else {
			this.data = t.getObject();
			this.errId = "";
			this.errReason = "";
			this.ok = true;

			// a reduced set
			if(has("result")) {
				// I assume here that the result field will _not_ be JSONObject.
				// therefore, the success of this try is a fatal error on my part.
				try {
					getJSONObject("result");
					throw "Unhandled exception. Contact developers.";
				} catch(e : Dynamic) {}
				this.rowCount = 1;
				var v = get("result");
				value = v;
				this.data =
				{
					rows : [{id: null, key:null, value: v}]
				};
			}
			else {
				// this is not correct in any view that defines a startkey or endkey, it
				// returns the total rows in the database
				// this.rowCount = getInt("total_rows");
				// the Null<rowCount> will not be updated unless it is requested
				this.rowCount = null;
				this.offset = optInt("offset",0);
			}
		}
	}

	/**
		Retrieves a list of Rows that matched this View.
	**/
	public function getRows() : List<Row>
	{	//{"total_rows":1000,"offset":0,"rows":[
		//{"id":"0","key":"0","value":{"rev":"2922574358"}}, ...
		var rv = new List<Row>();
		if(!ok)
			return rv;


		var a : JSONArray;
		//try {
			a = getJSONArray("rows");
		//} catch(e : Dynamic) { return rv; }
		trace(Std.string(a));
		var l = a.length;
		trace(l);
		for(i in 0...l) {
			if(a.get(i) != null && a.getString(i) != "null") {
				var dr = new Row(this.database, a.getJSONObject(i));
				//trace(Std.string(dr));
				dr.setDatabase(database);
				rv.add(dr);
			}
		}
		return rv;
	}

	public function getRowCount() : Int {
		if(rowCount == null) {
			if(!has("rows")) {
				rowCount = 0;
			}
			else {
				var a = getJSONArray("rows");
				rowCount = a.length;
			}
		}
		return rowCount;
	}

	/**
		Returns each row as a string representation of the Json object. Useful
		for debugging the result set, to see if the objects you are expecting
		from the query actually exist.
	**/
	public function getStrings() : List<String>
	{
		var rv = new List<String>();
		if(!ok)
			return rv;

		var a = getJSONArray("rows");
		var l = a.length;
		for(i in 0...l) {
			if(a.get(i) != null && a.getString(i) != "null") {
				rv.add(Std.string(a.getJSONObject(i)));
			}
		}
		return rv;
	}

	/**
		This will be true if there was no error during the query.
	**/
	public function isOk() {
		return ok;
	}

	/**
		Only available if the view has a reduce function, but is
		also stored as the first row.value
	**/
	public function getValue() : Dynamic {
		return value;
	}

	/**
		The view this result set was generated from.
	**/
	public function getView(?foo:String) : View {
		return this.view;
	}


	/**
		The error code
	**/
	public function getErrorId() : String {
		return errId;
	}

	/**
		Error message
	**/
	public function getErrorReason() : String {
		return errReason;
	}

	/**
		The number of rows in the result set. Also available as the
		property 'rowCount'.
	**/
	public function numRows() : Int {
		return rowCount;
	}
}