/*
 * Copyright (c) 2011, The Caffeine-hx project contributors
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

import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * A class of basic assertions macros that only generate code when the -debug
 * flag is used on the haxe compiler command line.
 **/
class Assert {
	/**
	* Asserts that expected is equal to actual
	* @param expected Any expression that can test against actual
	* @param actual Any expression that can test againt expected
	**/
	@:macro public static function isEqual( expected : Expr, actual : Expr ) : Expr {
		if(!Context.defined("debug"))
			return { expr : EBlock(new Array()), pos : Context.currentPos() };
		var pos = Context.currentPos();
		return
		{ expr : EIf(
			{ expr : EBinop(
				OpNotEq,
				expected,
				actual),
			pos : pos},
			{ expr : EThrow(
				{ expr : ENew(
					{
						sub : null,
						name : "FatalException",
						pack : ["chx", "lang"],
						params : []
					},
					[
						{ expr : EBinop(OpAdd,
							{ expr : EConst(CString("Assertion failed. Expected ")), pos : pos },
							{ expr : EBinop(
								OpAdd,
								{ expr : ECall({ expr : EField({ expr : EConst(CType("Std")), pos : pos },"string"),pos : pos },[expected]), pos : pos },
								{ expr : EBinop(OpAdd, { expr : EConst(CString(". Got ")), pos : pos }, { expr : ECall({ expr : EField({ expr : EConst(CType("Std")), pos : pos },"string"), pos : pos },[actual]), pos : pos }), pos:pos}
								),
							pos : pos
							}),
						pos : pos
						}
					]),
				pos : pos }),
			pos : pos },
			null),
		pos : pos };
	}

	/**
	* Asserts that expr evaluates to true
	* @param expr An expression that evaluates to a Bool
	**/
	@:macro public static function isTrue( expr:Expr ) : Expr {
		if(!Context.defined("debug"))
			return { expr : EBlock(new Array()), pos : Context.currentPos() };
		var pos = Context.currentPos();
		return
		{ expr : EIf(
			{ expr : EBinop(
				OpNotEq,
				{ expr : EConst(CIdent("true")), pos : pos },
				expr),
			pos : pos},
			{ expr : EThrow(
				{ expr : ENew(
					{
						sub : null,
						name : "FatalException",
						pack : ["chx", "lang"],
						params : []
					},
					[
						{ expr : EConst(CString("Assertion failed. Expected true but was false")), pos : pos }
					]),
				pos : pos }),
			pos : pos },
			null),
		pos : pos };
	}

	/**
	* Asserts that expr evaluates to false
	* @param expr An expression that evaluates to a Bool
	**/
	@:macro public static function isFalse( expr:Expr ) : Expr {
		if(!Context.defined("debug"))
			return { expr : EBlock(new Array()), pos : Context.currentPos() };
		var pos = Context.currentPos();
		return
		{ expr : EIf(
			{ expr : EBinop(
				OpNotEq,
				{ expr : EConst(CIdent("false")), pos : pos },
				expr),
			pos : pos},
			{ expr : EThrow(
				{ expr : ENew(
					{
						sub : null,
						name : "FatalException",
						pack : ["chx", "lang"],
						params : []
					},
					[
						{ expr : EConst(CString("Assertion failed. Expected false but was true")), pos : pos }
					]),
				pos : pos }),
			pos : pos },
			null),
		pos : pos };
	}

	/**
	* Checks that the passed expression is not null.
	* @param expr A string, class or anything that can be tested for null
	**/
	@:macro public static function isNotNull( expr:Expr ) : Expr {
		if(!Context.defined("debug"))
			return { expr : EBlock(new Array()), pos : Context.currentPos() };
		var pos = Context.currentPos();
		return
		{ expr : EIf(
			{ expr : EBinop(
				OpEq,
				{ expr : EConst(CIdent("null")), pos : pos },
				expr),
			pos : pos},
			{ expr : EThrow(
				{ expr : ENew(
					{
						sub : null,
						name : "FatalException",
						pack : ["chx", "lang"],
						params : []
					},
					[
						{ expr : EConst(CString("Assertion failed. Expected non null value")), pos : pos }
					]),
				pos : pos }),
			pos : pos },
			null),
		pos : pos };
	}

}