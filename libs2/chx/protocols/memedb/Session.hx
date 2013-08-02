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


/**
	Represents a connection to the memedb server <br />
	From the MemeDB docs: <br />
	A database must be named with all lowercase characters (a-z), digits (0-9), or any of the _$()+-/ characters and must end with a slash in the URL. The name has to start with characters.
**/
class Session {
	public var host(default, null) : String;
	public var port(default, null) : Int;

	private var username : String;
	private var password : String;
	private var token : String;

	private var portStr : String;
	private var lastTransaction : Transaction;

	public function new(host:String, port : Int, username : String, password : String) {
		this.host = host;
		this.port = port;
		this.portStr = Std.string(port);
		this.username = username;
		this.password = password;
		authenticate();
		if(token == null)
			throw "Unable to connect";
// 		trace("Connected with token " + this.token);
	}

	public function authenticate(?user : String, ?pass : String) : Bool {
		token = null;
		if(user != null)
			this.username = user;
		if(pass != null)
			this.password = pass;
		var args : Hash<String> = new Hash();
		args.set("username", username);
		args.set("password", password);
		var t = get("/_auth", args);
		if(!t.isOk())
			return false;
		this.token = t.getJSONObject().optString("token",null);
		return true;
	}

	public function createDatabase(name : String) : Database {
		//PUT /somedatabase/
		//Currently the content of the actual PUT is ignored by the webserver.
		//On success, HTTP status 201 is returned. If a database already exists a 409 error is returned.
		// {"error":"database_already_exists","reason":"Database \"test_suite_db\" already exists."}
		// 201 -> {"ok":true}

		var n = reformatName(name);
		var t = put(n);
		if(t.isOk())
			return getDatabase(name);
		return null;
	}

	public function deleteDatabase(db : Database) : Bool {
		return deleteDatabaseByName(db.getName());
	}

	public function deleteDatabaseByName( name : String ) : Bool {
		//DELETE /somedatabase/
		//On success, HTTP status 202 is returned. If the database doesn't exist, a 404 error is returned.
		var t = delete(reformatName(name));
		return t.isOk();
	}

	public function getDatabase(name:String) : Database {
		//To get information about a particular database, perform a GET operation on the database, e.g.
		//GET /somedatabase/ HTTP/1.0
		//The server's response is a JSON object similar to the following:
		//{"db_name": "dj", "doc_count":5, "doc_del_count":0, "update_seq":13, "compact_running":false, "disk_size":16845}
		// or on error:
		//{"error":"not_found","reason":"missing"}

		var t = get(reformatName(name));
		if(!t.isOk())
			return null;
		return new Database(this, t.getJSONObject());

	}

	/**
		Retrieve a list of valid databases on the server
	**/
	public function getDatabaseNames() : List<String> {
		// GET /_all_dbs
		// ["test_suite_db","test_suite_db_a","test_suite_db_b"]
		var t = get("_all_dbs");

		var respArr = t.getJSONArray();
		var dbs = new List<String>();
		for(i in 0...respArr.length) {
			dbs.add(respArr.getString(i));
		}
		return dbs;
	}

	/**
		Get last reponse from server
	**/
	public function getLastTransaction() : Transaction {
		return lastTransaction;
	}

	/**
		make sure there is a trailing slash on Database names
	**/
	function reformatName(n :String) {
		if(n.charAt(n.length-1) != "/")
			n += "/";
		return n;
	}

	function buildUrl(uri:String) {
		var root = "";
		if(uri.charAt(0) != "/")
			root = "/";
		return host + ":" + portStr + root + uri;
	}

	public function saveWithId( db: Database, d: Document, id:String) : Transaction
	{
		var t : Transaction = null;
		d.setDatabase(db);
		d.setId(id);
		if (id == null || id == "")
			t = post(db.uri, null, d.toString(), d.getMimeType());
		else
			t = put(db.uri + StringTools.urlEncode(id), null, d.toString(), d.getMimeType());

		if(!t.isOk())
			return t;

		try {
			//if (d.id == null || d.id == "")
			d.setId(t.getJSONObject().getString("id"));
			d.setRevision(t.getJSONObject().getString("rev"));
		}
		catch (e: Dynamic) {
			trace(e);
		}
		return t;

	}

	public function get(uri:String, ?args:Hash<String>) {
		var t = new Transaction("GET", buildUrl(uri), token, args);
		t.doRequest();
		lastTransaction = t;
		return t;
	}

	public function post(uri:String, ?args:Hash<String>, ?bodyText : String, ?contentType : String) {
		var t = new Transaction("POST", buildUrl(uri), token, args, contentType);
		if(bodyText != null)
			t.setBodyText(bodyText);
		t.doRequest();
		lastTransaction = t;
		return t;
	}

	public function put(uri:String, ?args:Hash<String>, ?bodyText : String, ?contentType : String) {
		var t = new Transaction("PUT", buildUrl(uri), token, args, contentType);
		if(bodyText != null)
			t.setBodyText(bodyText);
		t.doRequest();
		lastTransaction = t;
		return t;
	}

	public function delete(uri:String, ?args:Hash<String>) {
		var t = new Transaction("DELETE", buildUrl(uri), token, args);
		t.doRequest();
		lastTransaction = t;
		return t;
	}

}
