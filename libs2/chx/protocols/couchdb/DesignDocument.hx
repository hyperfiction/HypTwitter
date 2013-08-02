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

/*
Permanent views are stored inside special documents called design documents, and can be accessed via an HTTP GET request to the URI /{dbname}/{docid}/{viewname}, where {docid} has the prefix _view/ so that CouchDB recognizes the document as a design document.

To create a permanent view, the functions must first be saved into special design documents. The IDs of design documents must begin with _design/ and have a special views attribute that holds all the view functions.

A design document that defines all and by_lastname views might look like this:
{
   "_id":"_design/foo",
   "language":"javascript",
   "views": {
	 "all": {
		"map": "function(doc) { if (doc.Type == 'customer')  map(null, doc) }"
	 }
	 "by_lastname": {
		"map" : "function(doc) { if (doc.Type == 'customer')  map(doc.LastName, doc)"
	 }
     "bar": {
       "map":"function... ",
       "reduce":"function..."
     }
   }
}
*/

/**
	DesignDocument s define permanent views for a database. Views may be added,
	but they all must use the same language interpreter as the DesignDocument itself.
**/
class DesignDocument extends Document {
	/** the language interpreter is to use **/
	public var language(getLanguage, setLanguage) : String;
	public var name(default, setName) : String;

	public function new(name : String, ?language : String, ?database : Database) {
		super();
		this.name = name;
		if(language != null)
			this.language = language;
		else
			this.language = "javascript";
		this.database = database;
	}

	/**
		Add a view to this DesignDocument. This will set the DesignDocument in the
		provided view to this Document. If the view provided is not a DesignView,
		(ie. an AdHoc view) a name must be provided.
	**/
	public function addView(view : View, ?newName:String) {
		var dv : DesignView;
		if(view.language != null && view.language != "") {
			if(view.language != this.language)
				throw "View requires an incompatible script interpreter.";
			view.language = this.language;
		}
		if(Std.is(view,DesignView)) {
			dv = cast view;
			if(newName != null)
				dv.rename(newName);
		}
		else {
			if(newName == null || newName == "")
				throw "View must be named";
			dv = view.toDesignView(newName);
		}
		dv.setDesignDocument(this);
		var k = "views." + dv.getName();
		var def = dv.getDefinition();
		// the language is not needed in the view records.
		Reflect.deleteField(def, "language");
		set(k, def);
	}

	/**
		Returns the language any Views are to be interpreted with
	**/
	public function getLanguage() : String {
		return getString("language");
	}

	public function getName() : String {
		return this.name;
	}

	public function getPathEncoded() : String {
		return this.name;
	}

	/**
		Get a view. If it does not exist in the collection, null will be returned. If you
		modify the view that is returned, and want it save, re-add it to the
		DesignDocument with addView()
	**/
	public function getView(viewName : String) : DesignView {
		var v = null;
		var n = "views." + viewName;
		if (has(n)) {
			var o = new JSONObject(get(n));
			v = new DesignView(
				viewName,
				o.getString("map"),
				o.optString("reduce", null),
				this.language
			);
			v.setDesignDocument(this);
		}
		return v;
	}

	/**
		Set the language interpreter for this view script
	**/
	function setLanguage(v : String) : String {
		if(v == null)
			set("language", "javascript");
		else
			set("language", v);
		return v;
	}

	public function setName(n : String ) : String {
		if(n != name) {
			this.id = "_design/" + n;
			this.name = n;
		}
		return n;
	}

	public function removeViewNamed(name:String) {
		remove("views." + name);
	}
}
