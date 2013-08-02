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
	A couchdb Database interface to create, get, delete, update Documents and perform View operations.
**/
/*
How Do I Use Replication?
POST /_replicate?source=$source_database&target=$target_database
Where $source_database and $target_database can be the names of local database or full URIs of remote databases. Both databases need to be created before they can be replicated from or to.
*/
class Database {
	/** this is the name as returned by CouchDB **/
	public var name(default, null) : String;
	public var documentCount(default, null) : Int;
	public var documentDeletedCount(default, null) : Int;
	public var updateSeq(default, null) : Int;
	public var compactRunning(default, null) : Bool;
	public var diskSize(default, null) : Int;
	public var uri(default,null) : String;

	private var session : Session;

	public function new(session : Session, json : JSONObject) {
		//{"db_name":"mytestdb","doc_count":0,"doc_del_count":0,"update_seq":0,"compact_running":false,"disk_size":4096}
		this.session = session;
		this.name = json.getString("db_name");
		this.documentCount = json.getInt("doc_count");
		this.documentDeletedCount = json.getInt("doc_del_count");
		this.updateSeq = json.getInt("update_seq");
		this.compactRunning = json.getBool("compact_running");
		this.diskSize = json.getInt("disk_size");
		this.uri = "/" + StringTools.urlEncode(this.name) + "/";
	}

	public function bulkSave(docs : Array<Document>, ?options : DocumentOptions) : Bool {
		var qp = null;
		if(options != null)
			qp = options.getQueryParams();
		var body = JSON.encode({docs: docs});
		var t = session.post(this.uri + "_bulk_docs", qp, body);

		if(!t.isOk()) // 201 is success here
			return false;

		var newRevs = t.getJSONArray();
		for(i in 0...docs.length)
		{
			var d = docs[i];
			d.setId(newRevs.get(i).optString("id", d.getId()));
			d.setRevision(newRevs.get(i).getString("rev"));
		}
		return true;
	}

	/**
		Start a database compaction run
	**/
	public function compact() : Bool {
		var t = session.post(this.uri + "_compact");
		if(t.isOk())
			return true;
		return false;
	}

	/**
		Delete supplied document
	**/
	public function delete(d : Document) : Bool {
		var t = session.delete(this.uri + StringTools.urlEncode(d.getId()) + "?rev=" + d.getRevision());
		if(t.isOk())
			return true;
		return false;
	}

	/**
		Return all documents in database. This is keyed on the revision, so a filter
		could specify a starting revision number.
	**/
	public function getAll(?filter : Filter) : Result {
		return view("_all_docs", filter);
	}

	/**
		Ordered list of Documents by seq number. Filter could have a startKey or endKey
		to limit the results.
	**/
	public function getAllBySeq(?filter : Filter) : Result {
		return view("_all_docs_by_seq", filter);
	}

	/**
		Retrieves a specific document. To set options, provide a DocumentOptions object
	**/
	public function open(id:String, ?options:DocumentOptions) {
		var qp = null;
		if(options != null)
			qp = options.getQueryParams();
		var t = session.get(
			uri + StringTools.urlEncode(id),
			qp);
		if(!t.isOk())
			return null;
		var doc = new Document(t.getJSONObject());
		doc.setDatabase(this);
		return doc;
	}

	/**
	**/
	public function openDesignDocument(ddName : String, ?options:DocumentOptions) {
		var doc: DesignDocument = cast open("_design/"+ddName, options);
		if(doc == null) return null;

		var dd : DesignDocument = new DesignDocument(ddName,"javascript",this);
		dd.clear();
		dd.setAll(doc.data);
		dd.setName(ddName);
		return dd;
	}

	/**
		Retrieve document with it's revisions
	**/
	public function openWithRevisions(id : String) {
		return open(id,new DocumentOptions().showRevisionInfo(true));
	}

	/**
		Get the number of documents in the database. This number is as of
		when the database was retrieved from the Session, so it may be out of date.
	**/
	public function getDocumentCount() : Int {
		return this.documentCount;
	}

	/**
		Name of the database
	**/
	public function getName() : String {
		return this.name;
	}

	/**
		The update seq
	**/
	public function getUpdateSeq() : Int {
		return this.updateSeq;
	}


	/**
		Saves a Document. If docId is null, the server will generate an id.
	**/
	public function save(doc : Document) : Bool {
		//if(Std.is(doc,DesignDocument))
		//	return saveWithId(doc, untyped doc.getPathEncoded());
		return saveWithId(doc,doc.getId());
	}

	/**
		Save a document at the given _id. If docId is null or "", the document will
		be POSTed and a new docId will be retrieved. If docId is not null, the document
		will be PUT with that id.
	**/
	public function saveWithId( d: Document, id:String) : Bool {
		var t : Transaction;
		d.setDatabase(this);
		d.setId(id);
		if (id == null || id == "")
			t = session.post(uri, null, d.toString());
		else
			t = session.put(uri + StringTools.urlEncode(id), null, d.toString());

		if(!t.isOk())
			return false;

		try {
			//if (d.id == null || d.id == "")
			d.setId(t.getJSONObject().getString("id"));
			d.setRevision(t.getJSONObject().getString("rev"));
		}
		catch (e: Dynamic) {
			trace(e);
		}
		return true;
	}


	/**
		Runs the adhoc view from javascript string
	**/
	public function query(map : String, ?reduce : String, ?language : String ) : Result {
 		return view(new View(map, reduce, language));
	}

	/**
		Run the provided view. This is either a basic AdHoc View, a DesignView,
		or one by name String (ie. "company/all"). If a filter is provided, it
		will override any filter in the View.
	**/
	public function view(view : Dynamic, ?filter : Filter) : Result {
		var t : Transaction;
		var rv : Result;
		if(Std.is(view, NamedView) || Std.is(view, String)) {
			// GET /some_database/_view/company/all
			if(Std.is(view, String)) {
				view = new NamedView(cast view);
			}
			var n = view.getPathEncoded();
			var params = null;
			// Provided filter overrides that in the DesignView
			try {
				if(filter != null)
					params = filter.getQueryParams();
				else
 					params = view.getFilter().getQueryParams();
			} catch(e : Dynamic) {}

			var t = session.get(
				this.name + "/" + n,
				params);
			return new Result(this, view, t);
		}
		else if(Std.is(view, View)) { // AdHoc View
			//POST /some_database/_temp_view  HTTP/1.0
			t = session.post(
				this.name + "/" + view.getPathEncoded(),
				null,
				view.toString());
			rv = new Result(this, view, t);
		}
		else {
			throw "Invalid view.";
		}
		return rv;
	}

}
