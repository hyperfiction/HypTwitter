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
import chx.formats.json.JSON;
import chx.protocols.http.Request;

/**
	Handles the HTTP transaction with the MemeDB server. This class
	is used only internally.
**/
class Transaction {
	/** These statics are for getErrorReason **/
	public static var REASON_NOT_FOUND = "missing"; // errorId "not_found"
	public static var REASON_DB_NAME_ERROR = "illegal_database_name";
	/** unable to get a reason from MemeDB **/
	public static var REASON_UNKNOWN = "unknown";

	public static var DEFAULT_CONTENT_TYPE = "application/json";

	private var err : Bool;
	private var errmsg : String;
	private var http : Request;
	private var httpErrMsg : String;
	private var method : String;
	private var output : chx.io.BytesOutput;
	/** HTTP status code **/
	public var status(default,null) : Int;

	public function new(httpMethod: String, url:String, token:String, ?args:Hash<String>, ?contentType : String)
	{
		err = false;
		output = new chx.io.BytesOutput();

		http = new Request(url);
		//http.noShutdown = true;
		//http.cnxTimeout = 60; // seconds
		http.onData = onData;
		http.onError = onError;
		http.onStatus = onStatus;
		//http.setHeader("Connection", "close");
		if(contentType != null)
			http.setHeader("Content-Type", contentType);
		else
			http.setHeader("Content-Type", DEFAULT_CONTENT_TYPE);
		if(token != null && token != "")
			http.setHeader("MemeDB-Token", token);

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
		Initiate the transaction with the MemeDB server.
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
	var outputString:String;
	public function getBody() : String {

		// note: there is a problem in haxe-2 with multiple calls of getBytes on the
		// same stream

		if ( outputString == null )
		 outputString = output.getBytes().toString();
		return outputString;
	}

	/**
		The error code as returned by MemeDB
	**/
	public function getErrorId() : String {
		return try getJSONObject().optString("error",REASON_UNKNOWN) catch(e:Dynamic) REASON_UNKNOWN;
	}

	/**
		Error message returned by MemeDB
	**/
	public function getErrorReason() : String {
		return try getJSONObject().optString("reason",REASON_UNKNOWN) catch(e:Dynamic) REASON_UNKNOWN;
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
	* Get the http error code
	**/
	public function getHttpErrorNumber() : Null<Int> {
		if(httpErrMsg == null)
			return null;
		var ereg = ~/([0-9]+)$/;
		if(ereg.match(httpErrMsg))
			return Std.parseInt(ereg.matched(1));
		return null;
	}

	/**
		Returns the object of the response body
	**/
	public function getJSONObject() : JSONObject {
		return new JSONObject(getBody());
	}

	/**
		Return the response body as a JSONArray
	**/
	public function getJSONArray() : JSONArray {
		return JSONArray.fromObject(getBody());
	}

	/**
		Returns the object of the response body
	**/
	public function getObject() : Dynamic {
		return JSON.decode(getBody());
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

	/**
		Set the Content-Type to GIF.
	**/
	public function setContentTypeGIF() {
		http.setHeader("Content-Type", "image/gif");
	}

	/**
		Set the Content-Type to JPEG.
	**/
	public function setContentTypeJPG() {
		http.setHeader("Content-Type", "image/jpeg");
	}

	/**
		Set the Content-Type to PNG.
	**/
	public function setContentTypePNG() {
		http.setHeader("Content-Type", "image/png");
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
