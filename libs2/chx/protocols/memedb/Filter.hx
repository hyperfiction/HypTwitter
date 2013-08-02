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

import chx.formats.json.JSON;

/**
	A view Filter, which limits the rows returned in a view.
**/
class Filter {
	/** The number of rows to return **/
	public var count : Null<Int>;

	/** reverse order of result set **/
	public var descending : Bool;

	/** the last key to include in the result set **/
	public var endkey : Dynamic;

	/** Whether the starting key is included in results **/
	public var endkey_inclusive : Bool;

	/** get a specific key **/
	public var key : Dynamic;

	/** rows to skip **/
	public var skip : Int;

	/** return view rows, not reduced rows if true **/
	public var skip_reduce : Bool;

	/** the first key to start building a result set. See notes in setStartKey() **/
	public var startkey : Dynamic;

	/** Whether the starting key is included in results **/
	public var startkey_inclusive : Bool;

	/** The starting document ID **/
	//public var startDocId : String;

	/** Setting to false improves performance, but Meme may not have updated the view */
	public var update : Bool;

	public function new( ) {
		this.update = true;
	}

	/**
		The query params to be added to the URL for this Query
	**/
	public function getQueryParams() : Hash<String> {
		var rv = new Hash();
		if(count != null)
			rv.set("count", Std.string(count));
		if(descending != null && descending)
			rv.set("descending", "true");
		if(endkey != null)
			rv.set("endkey", JSON.encode(endkey));
		if(endkey_inclusive != null)
			rv.set("startkey_inclusive", Std.string(endkey_inclusive));
		if(key != null)
			rv.set("key", JSON.encode(key));
		if(skip != null)
			rv.set("skip", Std.string(skip));
		if(skip_reduce != null)
			rv.set("skip_reduce", Std.string(skip_reduce));
		if(startkey != null)
			rv.set("startkey", JSON.encode(startkey));
		if(startkey_inclusive != null)
			rv.set("startkey_inclusive", Std.string(startkey_inclusive));
// 		if(startDocId != null)
// 			rv.set("startkeydoc_id", startDocId);
// 		if(update != null && !update)
// 			rv.set("update", "false");
		return rv;
	}

	/**
		Number of entries to return. If you specify count=0 you don't get any data, but all meta-data for this View. The number of documents in this View for example.
	**/
	public function setCount(v : Int) : Filter {
		this.count = v;
		return this;
	}

	/**
		Reverse list. Note that the descending option is applied before any key filtering, so you may need to swap the values of the startkey and endkey options to get the expected results.
	**/
	public function setDescending(v : Bool) : Filter {
		this.descending = v;
		return this;
	}

	/**
		Key to stop listing at
	**/
	public function setEndKey(v : Dynamic, ?inclusive : Bool) : Filter {
		this.endkey = v;
		this.endkey_inclusive = if(inclusive == null) true else inclusive;
		return this;
	}

	/**
		Fetch a specific key
	**/
	public function setKey(v : Dynamic) : Filter {
		this.key = v;
		return this;
	}

	/**
		Number of rows to skip. The skip option should only be used with small values, as skipping a large range of documents this way is inefficient (it scans the index from the startkey and then skips N elements, but still needs to read all the index values to do that). For efficient paging use startkey and/or startkey_docid
	**/
	public function setSkip(v : Int) : Filter {
		this.skip = v;
		return this;
	}

	/**
		Any view that has a reduce function can be instructed to omit
		the reduce function and return the actual view results by
		setting this to true
	**/
	public function setSkipReduce(v : Bool) : Filter {
		this.skip_reduce = v;
		return this;
	}

	/**
		Key to start after. This is not the key that will be first in the Result set, but rather
		the key that marks when to start collecting rows. This makes paging very simple in that the
		next page would be startKey'd by the last record in the current view. If you wish to include
		the key in the set, follow the http://wiki.apache.org/memedb/ViewCollation order of keys, and
		reduce your startkey by one level of precedence.
	**/
	public function setStartKey(v : Dynamic, ?inclusive:Bool) : Filter {
		this.startkey = v;
		this.startkey_inclusive = if(inclusive == null) false else inclusive;
		return this;
	}

}
