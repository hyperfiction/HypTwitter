/*
 * Copyright (c) 2010, The Caffeine-hx project contributors
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

package chx.text;
import chx.io.Output;
import chx.lang.FatalException;
import chx.lang.NullPointerException;

/**
 * A custom printf writer that writes to an Output. Handlers may be registered
 * for alpha characters and the % sign, which are then responsible for writing
 * to the output.
 * 
 * Each handler is of the form (out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void
 * where props is a flag int of text.Sprintf kValues, the len is the field length (or null if it
 * is not specified) for padding and precision is a length of the output.
 * @author Russell Weir
 */
class CallbackPrintf 
{
	var handlers : IntHash<Output->Dynamic->Int->Null<Int>->Null<Int>->Void>;
	
	public function new() 
	{
		handlers = new IntHash();
	}
	
	/**
	 * Registers a handler for the specified character which would appear after a 
	 * % sign. The handler must accept the output buffer, the current argument,
	 * and an optional field width modifier. Only the characters a-z, A-Z and 
	 * % may be registered with handlers.
	 * 
	 * <pre>
	 * c = new CallbackPrintf();
	 * // to handle %s with function 'writeString'
	 * c.registerCallback("s", writeMyString);
	 * ...
	 * function writeMyString(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
	 *    if(precision == null)
	 * 		output.writeString(Std.string(arg));
	 * 	  else
	 *		output.writeString(Std.string(arg).substr(0, precision));
	 *    return this;
	 * }
	 * </pre>
	 * @param	char The character after a % sign to handle
	 * @param	cb The callback function that writes to the output
	 * @throws chx.lang.NullPointerException if the char is null
	 * @throws chx.lang.FatalException if anything other than [a-zA-Z%] is registered
	 */
	public function registerCallback(char:String, cb: Output->Dynamic->Int->Null<Int>->Null<Int>->Void) {
		var v : Null<Int> = char.charCodeAt(0);
		if (v == null)
			throw new NullPointerException("Character must not be null");
		var isAlpha : Bool = ((v >= 'a'.code && v <= 'z'.code) || (v >= 'A'.code && v <= "Z".code));
		if (v != '%'.code && !isAlpha)
			throw new FatalException("Only characters a-z, A-Z and % may be registered");
		handlers.set(v, cb);
	}
	
	/**
	 * Write the format string with args replacement to the Output
	 * @param	out An output. Only writeString is called from this method
	 * @param	format a format string
	 * @param	args array of args to replace into format
	 */
	public function write(out:Output, format:String, args:Array<Dynamic> = null) {
		if (args == null)
			args = new Array();
		var idx : Int = 0;
		var argIndex : Int = 0;
		var pix : Int = 0;
		var arg : Dynamic = null;
		var length:Null<Int>=null;
		var precision:Null<Int>=null;
		var properties:Int=0;		// options: left justified, zero padding, etc...
		var fieldCount:Int = 0;		// tracks number of sections in field
		var fieldOutcome:Dynamic;	// when set to true, field parsed successfully
									// when set to a string, error resulted

		while (idx < format.length) {
			pix = format.indexOf('%', idx);
			if (pix == -1) {
				out.writeString(format.substr(idx));
				idx = format.length;
				break;
			} else {
				out.writeString(format.substr(idx, pix-idx));
				
				fieldOutcome = '** sprintf: invalid format at ' + argIndex + ' **';
				length = null;
				properties = fieldCount = 0;
				precision = null;
				idx = pix + 1;
				arg = args[argIndex++];

				while ( Std.is(fieldOutcome, String) && (idx < format.length)) {
					var ch = format.charCodeAt(idx++);
					switch (ch) {
						case '#'.code:
							if (fieldCount == 0) {
								properties |= Sprintf.kALT_FORM;
							} else {
								fieldOutcome = '** sprintf: "#" came too late **';
							}
						case '-'.code:
							if (fieldCount == 0) {
								properties |= Sprintf.kLEFT_ALIGN;
							} else {
								fieldOutcome = '** sprintf: "-" came too late **';
							}
						case '+'.code:
							if (fieldCount == 0) {
								properties |= Sprintf.kSHOW_SIGN;
							} else {
								fieldOutcome = '** sprintf: "+" came too late **';
							}
						case ' '.code:
							if (fieldCount == 0) {
								properties |= Sprintf.kPAD_POS;
							} else {
								fieldOutcome = '** sprintf: " " came too late **';
							}
						case '.'.code:
							if (fieldCount < 2) {
								fieldCount = 2;
								precision = 0;
							} else {
								fieldOutcome = '** sprintf: "." came too late **';
							}
						case '0'.code,'1'.code,'2'.code,'3'.code,'4'.code,'5'.code,'6'.code,'7'.code,'8'.code,'9'.code:
							if(ch == '0'.code && fieldCount == 0) {
								properties |= Sprintf.kPAD_ZEROES;
							}
							else {
								if (fieldCount == 3) {
									fieldOutcome = '** sprintf: shouldn\'t have a digit after h,l,L **';
								} else if (fieldCount < 2) {
									fieldCount = 1;
									if (length == null)
										length = 0;
									length = (length * 10) + (ch - "0".code);
								} else {
									if (precision == null)
										precision = 0;
									precision = (precision * 10) + (ch - "0".code);
								}
							}
						case '%'.code:
							if (handlers.exists('%'.code)) {
								handlers.get('%'.code)(out, arg, properties, length, precision);
							}
							else {
								out.writeString("%");
								argIndex--;
							}
							fieldOutcome = true;
						default:
							if (handlers.exists(ch)) {//Output->Dynamic->Int->Null<Int>->Null<Int>
								handlers.get(ch)(out, arg, properties, length, precision);
								fieldOutcome = true;
							} else {
								fieldOutcome = '** sprintf: ' + Std.string(ch - "0".code) + ' not supported **';
							}
					}
				}
#if debug
				if (fieldOutcome != true) {
					out.writeString(Std.string(fieldOutcome));
				}
#end
			}
		}
	}
}