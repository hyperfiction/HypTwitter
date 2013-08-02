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

package chx.protocols.couchdb;

import chx.formats.json.JSONObject;
import chx.formats.json.JSONArray;
import chx.formats.json.JSON;

/**
	Handles the HTTP transaction with the CouchDB server. This class
	is used only internally.
**/
class Transaction {
	/** These statics are for getErrorReason **/
	public static var REASON_NOT_FOUND = "missing"; // errorId "not_found"
	public static var REASON_DB_NAME_ERROR = "illegal_database_name";
	/** unable to get a reason from CouchDB **/
	public static var REASON_UNKNOWN = "unknown";

	private var err : Bool;
	private var errmsg : String;
	private var http : protocols.http.Request;
	private var httpErrMsg : String;
	private var method : String;
	private var output : chx.io.StringOutput;
	/** HTTP status code **/
	public var status(default,null) : Int;

	public function new(httpMethod: String, url:String, ?args:Hash<String>)
	{
		err = false;
		output = new chx.io.StringOutput();
		var me = this;
		output.close = function() {
			me.onData(me.output.toString());
		};

		http = new protocols.http.Request(url);
		//http.noShutdown = true;
		//http.cnxTimeout = 60; // seconds
		http.onData = onData;
		http.onError = onError;
		http.onStatus = onStatus;
		//http.setHeader("Connection", "close");
		http.setHeader("Content-Type", "application/json");

		// check that method is ok.
		switch(httpMethod) {
		case "GET":
		case "POST":
		case "PUT":
		case "DELETE":
			default:
			throw "invalid request method";
		}
		this.method = httpMethod;

		// GET/POST params
		if(args != null) {
			for(k in args.keys()) {
				http.setParameter(k, args.get(k));
			}
		}
	}


	/**
		Initiate the transaction with the CouchDB server.
	**/
	public function doRequest() {
		try {
			switch(method) {
			case "GET":
				http.customRequest(false, output);
			case "POST":
				http.customRequest(true, output);
			case "PUT":
				http.customRequest(true, output, null, method);
			case "DELETE":
				http.customRequest(false, output, null, method);
			default:
				throw "invalid request method";
			}
		}
		catch(e:String) {
			err = true;
			errmsg = e;
		}
		catch(e:Dynamic) {
			err = true;
			errmsg = Std.string(e);
		}
	}

	/**
		Returns the raw response body
	**/
	public function getBody() : String {
		return this.output.toString();
	}

	/**
		The error code as returned by CouchDB
	**/
	public function getErrorId() : String {
		return getJSONObject().optString("error",REASON_UNKNOWN);
	}

	/**
		Error message returned by CouchDB
	**/
	public function getErrorReason() : String {
		return getJSONObject().optString("reason",REASON_UNKNOWN);
	}

	/**
		Retrieve the specified header from the response.
	**/
	public function getHeader(key:String) : String {
		return untyped http.responseHeaders.get(key);
	}

	/**
		Get the http error message
	**/
	public function getHttpError() : String {
		return httpErrMsg;
	}

	/**
		Returns the object of the response body
	**/
	public function getJSONObject() : Dynamic {
		return new JSONObject(output.toString());
	}

	/**
		Return the response body as a JSONArray
	**/
	public function getJSONArray() : JSONArray {
		return JSONArray.fromObject(output.toString());
	}

	/**
		Returns the object of the response body
	**/
	public function getObject() : Dynamic {
		return JSON.decode(output.toString());
	}

	/**
		Return Http status code
	**/
	public function getStatus() : Int {
		return http.status;
	}

	/**
		True if the Transaction is successful
	**/
	public function isOk() : Bool {
		return !err;
	}

	/**
		Set the text that gets sent in an outgoing transaction with
		the server. This is where the JSONObjects are put for PUT etc.
	**/
	public function setBodyText(s: String) {
		http.setBodyText(s);
	}

	/**
		Set the Content-Type to be sent during the request.
	**/
	public function setContentType(s : String) {
		http.setHeader("Content-Type", s);
	}

	//////////////////////////////////////////
	//                Events                //
	//////////////////////////////////////////

	function onData(s : String) {
	}

	function onError(s : String) {
		this.httpErrMsg = s;
		err = true;
	}

	function onStatus(status : Int) {
		this.status = status;
		if(status < 300)
			err = false;
		else
			err = true;
	}
}
