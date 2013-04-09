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

package chx.formats.json;

class JSONArray {
	public var data(default, null) : Array<Dynamic>;
	public var length(getLength, null) : Int;

	public function new() {
		var data = new Array();
	}

	public function getLength() : Int {
		return data.length;
	}

	public function get(idx : Int) : Dynamic {
		return data[idx];
	}

	public function getJSONObject(idx : Int) : JSONObject {
		return new JSONObject(get(idx));
	}

	public function getString(idx : Int) : String {
		if(idx < 0)
			throw new JSONException("invalid index");
		if(idx >= data.length)
			return "null";
		if(Std.is(data[idx], String))
			return cast data[idx];
		return Std.string(data[idx]);
	}

	public function optString(idx:Int,defaultValue:String=null) : String {
		return try {
			getString(idx);
		} catch(e:Dynamic) {
			defaultValue;
		}
	}

	public static function fromObject(s : String) {
		var ja = new JSONArray();
		ja.data = cast JSON.decode(s);
		return ja;
	}
}
