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

class JSONObject {
	public var data(default,null) : Dynamic;

	/**
		Initial data may be a JSON formatted String, JSONObject, or an
		Object, or null.
	**/
	public function new(?initialData : Dynamic) {
		if(initialData == null)
			this.data = {};
		else if(Std.is(initialData, String))
			this.data = JSON.decode(initialData);
		else if(Std.is(initialData, JSONObject))
			this.data = initialData.data;
		else if(Reflect.isObject(initialData))
			this.data = initialData;
		else
			throw new JSONException("JSONObject can not parse initialData");
	}

	public function toString() {
		if(data == null) return "";
		return JSON.encode(data);
	}

	static function DOES_NOT_EXIST(k:String) {
		return "JSON key '"+k+"' does not exist";
	}

	static function CAN_NOT_CONVERT(k:String, t:String) {
		return "JSON key '"+k+"' can not be converted to type '"+t+"'";
	}

	/**
		Erases all keys/data
	**/
	public function clear() {
		data = {};
	}

	/**
		Return a new JSON Object by appending [j] to this. Fields
		in [j] will overwrite [this]
	**/
	public function concat(j : JSONObject) : JSONObject {
		var d = {};
		var a = [this.data, j.data];
		for(o in a) {
			for(i in Reflect.fields(o))
				Reflect.setField(d, i, Reflect.field(o, i));
		}
		var nj = new JSONObject();
		nj.data = d;
		return nj;
	}

	/**
		Descend down an object dot notation path to recover the object there.
		Returns null if the object, or any path part, does not exist.
	**/
	public function get(k : String) : Dynamic {
		if(data == null) return null;

		var kp = k.split(".");
		var o = data;
		for(i in kp) {
			if(!Reflect.hasField(o, i)) {
				return null;
			}
			o = Reflect.field(o, i);
		}
		return o;
	}

	/**
		Returns a bool.
	**/
	public function getBool(key : String) : Bool {
		if(!has(key))
			throw new JSONException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(Std.is(o, Bool))
			return o;
		if(Std.is(o,String)) {
			var s = Std.string(o).toLowerCase();
			if(s == "true")
				return true;
			if(s == "false")
				return false;
		}
		throw new JSONException(CAN_NOT_CONVERT(key, "Bool"));
		return false;
	}

	public function getFloat(key : String) : Float {
		if(!has(key))
			throw new JSONException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(Std.is(o,Float)) {
			return o;
		}
		if(Std.is(o,Int)) {
			return o * 1.0;
		}
		var rv : Float;
		try {
			rv =  Std.parseFloat(Std.string(o));
		} catch(e : Dynamic) {
			throw new JSONException(CAN_NOT_CONVERT(key, "Float"));
		}
		return rv;
	}

	public function getInt(key : String) : Int {
		if(!has(key))
			throw new JSONException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(Std.is(o,Int))
			return o;
		if(Std.is(o,String)) {
			return Std.parseInt(Std.string(o));
		}
		if(Std.is(o,Float)) {
			return Std.int(o);
		}
		throw new JSONException(key + " is not an Int.");
		return 0;
	}

	/**
		Returns a JSONArray from the specified key <br />
		TODO: Optimize.
	**/
	public function getJSONArray(key : String) : JSONArray {
		if(!has(key))
			throw new JSONException(DOES_NOT_EXIST(key));
		return JSONArray.fromObject(JSON.encode(get(key)));
	}

	/**
		Return key as a new JSON Object. If it cannot be converted,
		an exception is thrown.
	**/
	public function getJSONObject(key : String) : JSONObject {
		if(!has(key))
			throw new JSONException(DOES_NOT_EXIST(key));
		var rv : JSONObject;
		try {
			rv = new JSONObject(get(key));
		}
		catch(e : Dynamic) {
			throw new JSONException(CAN_NOT_CONVERT(key,"JSONObject"));
		}
		return rv;
	}

	/**
		Throws JSONException if key does not exist
	**/
	public function getString(key : String) : String {
		if(!has(key))
			throw new JSONException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(o == null)
			return null;
		if(Std.is(o,String))
			return o;
		return Std.string(o);
	}

	/**
		Check if key [k] exists
	**/
	public function has(k : String) : Bool {
		if(data == null) return false;
		var kp = k.split(".");
		var o = data;
		for(i in kp) {
			if(!Reflect.hasField(o, i))
				return false;
			o = Reflect.field(o, i);
		}
		return true;
	}

	public function optBool(key:String, ?defaultValue : Bool) : Bool {
		return try {
			getBool(key);
		} catch (e : JSONException) {
			defaultValue;
		}
	}

	public function optFloat(key:String, ?defaultValue : Float) : Float {
		return try {
			getFloat(key);
		} catch (e : JSONException) {
			defaultValue;
		}
	}

	public function optInt(key:String, ?defaultValue : Int) : Null<Int> {
		return try {
			getInt(key);
		} catch (e : JSONException) {
			defaultValue;
		}
	}

	public function optJSONArray(key:String, defaultValue:JSONArray=null) : JSONArray
	{
		return try {
			getJSONArray(key);
		} catch (e : JSONException) {
			defaultValue;
		}
	}

	public function optJSONObject(key:String, defaultValue:JSONObject=null) : JSONObject
	{
		return try {
			getJSONObject(key);
		} catch (e : JSONException) {
			defaultValue;
		}
	}

	public function optString(key:String, ?defaultValue : String) : String {
		return try {
			getString(key);
		} catch (e : JSONException) {
			defaultValue;
		}
	}

	/**
		Remove data on key [k]
	**/
	public function remove(k :String) {
		if(data == null) {
			data = {};
			return;
		}
		var kp = k.split(".");
		var o = data;
		var lastO = data;
		var key : String = null;
		for(i in kp) {
			lastO = o;
			if(!Reflect.hasField(o, i))
				Reflect.setField(o, i, {});
			o = Reflect.field(o, i);
			key = i;
		}
		Reflect.deleteField(lastO, key);
	}

	/**
		Set key [k] to value [v]
	**/
	public function set(k :String, v : Dynamic) {
		if(data == null)
			data = {};
		var kp = k.split(".");
		var o = data;
		var lastO = data;
		var key : String = null;
		for(i in kp) {
			lastO = o;
			if(!Reflect.hasField(o, i))
				Reflect.setField(o, i, {});
			o = Reflect.field(o, i);
			key = i;
		}
		if(Std.is(v, JSONObject))
			Reflect.setField(lastO, key, v.data);
		else
			Reflect.setField(lastO, key, v);
	}

	/**
		Add all fields from object o to this
	**/
	public function setAll(o:Dynamic) {
		if(!Reflect.isObject(o))
			throw new JSONException("Must be an object");
		for(i in Reflect.fields(o))
			Reflect.setField(data,i, Reflect.field(o, i));
	}
}


