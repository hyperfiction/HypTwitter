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

class BinaryDocument implements Document {
	public static var CONTENT_TYPE_OCTET = "application/octet-stream";
	public static var CONTENT_TYPE_PNG = "image/png";
	public static var CONTENT_TYPE_JPG = "image/jpeg";
	public static var CONTENT_TYPE_GIF = "images/gif";
	public static var CONTENT_TYPE_NEKO = "application/neko";
	public var id(getId, setId) : String;
	public var revision(getRevision, setRevision) : String;

	private var database : Database;
	private var data : String;
	private var mimetype : String;

	/**
		Create a new document.
	**/
	public function new(id:String, ?data : String) {
		if(id != null)
			setId(id);
		this.data = data;
	}

	public function getId() : String { return id; }
	public function getRevision() : String { return revision; }
	public function getMimeType() : String { return mimetype; }
	public function isMimeType(mt:String) : Bool { return mimetype == mt; }
	/**
		Refresh for binary documents will simply reload.
	**/
	public function refresh() {
		reload();
	}

	/**
		Reloads this document entirely, overwriting all changes.
	**/
	public function reload() {
		if(database != null) {
			var d : BinaryDocument = cast database.open(
				getId(),
				new DocumentOptions().byRevision(getRevision()));
			this.data = d.data;
			this.mimetype = d.mimetype;
		}
	}
	public function setDatabase(db: Database) : Void { this.database = db; }
	public function setId(id : String) : String { return this.id = id; }
	public function setMimeType(mt:String) : String { return mimetype = mt; }
	public function setRevision(v : String) : String { return this.revision = v; }
	public function toString() : String { return data; }

#if (neko || php)
	public function readFile(p:String) {
		#if neko
		 data = neko.io.File.getContent(p);
		#else
		 data = php.io.File.getContent(p);
		#end
		var ext = p.substr(p.lastIndexOf(".") + 1).toLowerCase();
		switch(ext) {
		case "jpg", "jpeg":
			setMimeType(CONTENT_TYPE_JPG);
		case "png":
			setMimeType(CONTENT_TYPE_PNG);
		case "gif":
			setMimeType(CONTENT_TYPE_GIF);
		case "n":
			setMimeType(CONTENT_TYPE_NEKO);
		default:
			setMimeType(CONTENT_TYPE_OCTET);
		}

	}
#end
}
