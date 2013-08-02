package chx.sys.db;

interface ResultSet {

	var length(getLength,null) : Int;
	var nfields(getNFields,null) : Int;


	function hasNext() : Bool;
	function next() : Dynamic;
	function results() : List<Dynamic>;
	function getResult( n : Int ) : String;
	function getIntResult( n : Int ) : Int;
	function getFloatResult( n : Int ) : Float;

}
