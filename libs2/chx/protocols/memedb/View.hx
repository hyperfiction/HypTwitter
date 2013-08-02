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

/**
	A dynamic, or "AdHoc", View. Some map examples: <br />
	function (doc) { emit(doc.id, { Name: doc.name} ); } <br />
<pre>
{"id":"0","key":"0","value":{"Name":"Jill"}},
{"id":"1","key":"1","value":{"Name":"Judy"}},
{"id":"2","key":"2","value":{"Name":"Jim"}},
</pre>
	A 'senior citizens' map function<br />
	function (doc) { if (doc.age >= 65) { emit(null, {Name:doc.name, Age: doc.age}); }}<br />
<pre>
"id":"5","key":null,"value":{"Name":"Jack","Age":89}},
{"id":"6","key":null,"value":{"Name":"Judy","Age":92}},
{"id":"9","key":null,"value":{"Name":"Jaqueline","Age":89}}
</pre>
<br />
A reduce function: <br />
<pre>
function(keys, values) { return sum(values); };
</pre>
**/

/*
API change
http://mail-archives.apache.org/mod_mbox/incubator-memedb-dev/200805.mbox/%3c8A150DFE-97BB-41D5-82D4-04D15B34ECFB@apache.org%3e
*/

class View {
	/** the limits on the view **/
	public var filter : Filter;
	/** the language interpreter is to use **/
	public var language(getLanguage, setLanguage) : String;
	/** the mapping function (WHERE clause)**/
	public var mapFunction(getMapFunction,setMapFunction) : String;
	/** the reduce (summation etc.) function **/
	public var reduceFunction(getReduceFunction,setReduceFunction) : String;

	/** the name of the view **/
	private var name : String;
	private var json : JSONObject;


	public function new( ?map : String, ?reduce : String, ? language : String )
	{
		this.json = new JSONObject();
		this.name = "_temp_view";

		this.mapFunction = map;
		this.reduceFunction = reduce;
		this.language = language;
	}

	public function toString() {
		return json.toString();
	}

	/**
		Returns the underlying object
	**/
	public function getDefinition() : Dynamic {
		return json.data;
	}

	/**
		The view Filter
	**/
	public function getFilter() : Filter {
		return filter;
	}

	/**
		Returns the language this script is interpreted with.
	**/
	public function getLanguage() : String {
		return json.optString("language", "javascript");
	}

	/**
		The map function, if one exists.
	**/
	public function getMapFunction() : String {
		return json.optString("map", null);
	}

	/**
		The view name
	**/
	public function getName() : String {
		return name;
	}

	/**
		Return the name URL encoded, the full path for this view.
	**/
	public function getPathEncoded() : String {
		// ad-hoc requires no encoding.
		return name;
	}

	/**
		The reduce function, if one exists
	**/
	public function getReduceFunction() : String {
		return json.optString("reduce", null);
	}

	/**
		Setting the filter to null removes it.
	**/
	public function setFilter(f : Filter) : Filter {
		this.filter = f;
		return f;
	}

	/**
		Set the language interpreter for this view script
	**/
	public function setLanguage(v : String) : String {
		// when not provided, javascript is the default that MemeDB will use
		if(v == null)
			//json.set("language", "javascript");
			json.remove("language");
		else
			json.set("language", v);
		return v;
	}

	public function setMapFunction(code : String) : String {
		if(code == null)
			json.remove("map");
		else
			json.set("map", code);
		return code;
	}


	public function setReduceFunction(code:String) : String {
		if(code == null)
			json.remove("reduce");
		else
			json.set("reduce", code);
		return code;
	}

	/**
		Changes an AdHoc view into a DesignView, suitable for attaching
		to a DesignDocument.
	**/
	public function toDesignView(newName:String, ?doc : DesignDocument) : DesignView {
		var rv = new DesignView(newName, this.mapFunction, this.reduceFunction, this.language);
		//trace(rv);
		if(doc != null) {
			doc.addView(rv);
			//rv.setDesignDocument(doc);
		}

		return rv;
	}
}