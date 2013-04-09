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

/**
	The Row type of document may or may not represent a Document that exists in the
	database, depending on the query that generated it. Therefore, the distinction is
	made through the isRecord() function. If it is a record, it may, again depending
	on the view query, not have all the data associated with the actual record in
	the database.
**/
class Row extends Document {
	public var key(default, null) : String;
	public var value(default, null) : Dynamic;

	private var isRecord : Bool;

	public function new(db : Database, o:JSONObject) {
		super(o);
		this.database = db;

		this.key = o.getString("key");
		try {
			//{"id":"0","key":"0","value":{"rev":"2807216695"}}
			this.value = o.getJSONObject("value");
		}
		catch(e : Dynamic) {
			//{"id":"8","key":null,"value":97}
			this.value = o.get("value");
		}
		try {
			//{"id":"0","key":"0","value":{"rev":"2807216695"}}
			this.revision = this.value.getString("rev");
			this.isRecord = true;
		}
		catch(e :Dynamic) {
			//{"id":"8","key":null,"value":97}
			this.isRecord = false;
		}
		if(isRecord)
			this.id = get("id");
	}

	override public function getId() : String {
		if(isRecord)
			return super.getId();
		return optString("id");
	}

	/**
		A row's value may be a simple type, or a Json object.
	**/
	public function getValue() : Dynamic {
		return this.value;
	}

	override public function refresh() {
		if(!isRecord)
			throw "Row is not a database record.";
		return super.refresh();
	}

	override public function reload() {
		if(!isRecord)
			throw "Is not a database record.";
		return super.reload();
	}

	override public function setId(id:String) : String {
		if(!isRecord)
			throw "Is not a database record.";
		return super.setId(id);
	}

}

