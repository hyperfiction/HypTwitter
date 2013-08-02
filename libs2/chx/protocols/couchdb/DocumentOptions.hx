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

/**
	DocumentOptions are used in Database.open(). To fetch a specific revision
	of a document, db.open(id, new DocumentOptions().byRevision("abcdef"))
**/
class DocumentOptions {

	private var params : Hash<String>;

	public function new() {
		params = new Hash();
	}

	public function getQueryParams() : Hash<String> {
		return params;
	}

	/**
		Specify a revision to fetch.
	**/
	public function byRevision(revison : String) : DocumentOptions {
		params.set("rev", revison);
		return this;
	}

	/**
		Only show the revisions of a document. Will clear and byRevision() or
		showRevisionInfo() setting.
	**/
	public function showRevisionInfo(v :Bool) : DocumentOptions {
		if(v)
			params.set("revs", "true");
		else
			params.remove("revs");
		return this;
	}

	/**
		Add revision metadata info to document.
	**/
	public function showMetadata( v : Bool) : DocumentOptions {
		if(v)
			params.set("full", "true");
		else
			params.remove("full");
		return this;
	}


}