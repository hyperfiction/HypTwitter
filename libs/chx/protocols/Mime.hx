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

package chx.protocols;

class Mime {
	static public var extmap 	: Hash<String>;

	static function __init__() {
		extmap = new Hash<String>();
		extmap.set("gif", "image/gif");
		extmap.set("jpeg", "image/jpeg");
		extmap.set("jpg", "image/jpeg");
		extmap.set("png", "image/png");
		extmap.set("css", "text/css");
		extmap.set("html", "text/html");
		extmap.set("htm", "text/html");
		extmap.set("txt", "text/plain");
		extmap.set("js", "application/javascript");
		extmap.set("pdf", "application/pdf");
		extmap.set("xml", "text/xml");
		extmap.set("wav", "audio/x-wav");
		//extmap.set("", "");
	}

	static public function extensionToMime(ext : String) : String {
		if(extmap.exists(ext))
			return extmap.get(ext);
		return "unknown/unknown";
	}
}
