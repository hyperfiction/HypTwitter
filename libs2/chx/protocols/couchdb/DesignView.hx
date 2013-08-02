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
	A DesignView is a View that is stored in a Database's design document. The name
	parameter should be the name of this view without the DesignDocument name. That
	is, if the DesignDocument is named 'testviews', and this DesignView is supposed
	to be testviews/by_age, the name of this DesignView should be set to by_age only.
**/

/*
Once this document is saved into a database, then the all view can be retrieved at the URL:
GET /some_database/_view/company/all
*/
class DesignView extends NamedView {
	var document : DesignDocument;

	public function new( name : String, ?map : String, ?reduce : String, ? language : String)
	{
		super(name);
		//super(map, reduce, language);
		this.mapFunction = map;
		this.reduceFunction = reduce;
		this.language = language;
		this.rename(name);
	}

	/**
		Return the name URL encoded, the full path for this view.
	**/
	override public function getPathEncoded() : String {
		var fullpath = "_view/" + StringTools.urlEncode(document.name) + "/" + StringTools.urlEncode(name);
		return fullpath;
	}

	/**
		This is usually just called by DesignDocument.addView(), but may also be
		specified. Setting the DesignDocument here does not attach the view to
		the DesignDocument, however.
	**/
	public function setDesignDocument(v : DesignDocument) {
		this.document = v;
		return v;
	}

	/**
		Change the name of this view. If it is attached to a DesignDocument, then
		the view will be renamed in the DesignDocument as well.
	**/
	public function rename(name : String) {
		if(document != null) {
			document.removeViewNamed(this.name);
		}
		this.name = name;
		if(document != null) {
			document.addView(this);
		}
	}
}