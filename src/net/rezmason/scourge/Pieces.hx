package net.rezmason.scourge;

class Pieces {

	public static var ORIGIN_X:Int = 1;
	public static var ORIGIN_Y:Int = 1;
	
	public static var O_PIECE:Array<Int> = [0, 0, 0, 1, 1, 0, 1, 1, ];
	
	private static var  ONE:Array<Array<Int>> = [[0, 0, ]];
	private static var  TWO:Array<Array<Int>> = [[0, 0, 0, 1, ], [0, 0, 1, 0, ]];
	private static var  THREE_STRAIGHT:Array<Array<Int>> = [[0, 0, 0, 1, 0, 2, ], [0, 0, 1, 0, 2, 0, ]];
	private static var  THREE_BENT:Array<Array<Int>> = [[0, 0, 0, 1, 1, 0, ], [0, 0, 0, 1, 1, 1, ], [0, 1, 1, 0, 1, 1, ], [0, 0, 1, 0, 1, 1, ]];
	private static var  I:Array<Array<Int>> = [[0, 0, 1, 0, 2, 0, 3, 0, ], [0, 0, 0, 1, 0, 2, 0, 3, ]];
	private static var  L:Array<Array<Int>> = [[0, 0, 1, 0, 2, 0, 2, 1, ], [0, 0, 0, 1, 0, 2, 1, 0, ], [0, 0, 0, 1, 1, 1, 2, 1, ], [0, 2, 1, 0, 1, 1, 1, 2, ]];
	private static var  J:Array<Array<Int>> = [[0, 1, 1, 1, 2, 0, 2, 1, ], [0, 0, 1, 0, 1, 1, 1, 2, ], [0, 0, 0, 1, 1, 0, 2, 0, ], [0, 0, 0, 1, 0, 2, 1, 2, ]];
	private static var  T:Array<Array<Int>> = [[0, 0, 1, 0, 1, 1, 2, 0, ], [0, 0, 0, 1, 0, 2, 1, 1, ], [0, 1, 1, 0, 1, 1, 2, 1, ], [0, 1, 1, 0, 1, 1, 1, 2, ]];
	private static var  S:Array<Array<Int>> = [[0, 1, 0, 2, 1, 0, 1, 1, ], [0, 0, 1, 0, 1, 1, 2, 1, ]];
	private static var  Z:Array<Array<Int>> = [[0, 0, 0, 1, 1, 1, 1, 2, ], [0, 1, 1, 0, 1, 1, 2, 0, ]];
	private static var  O:Array<Array<Int>> = [O_PIECE];

	private static var  R_ONE:Array<Array<Float>> = [[0.5, 0.5,]];
	private static var  R_TWO:Array<Array<Float>> = [[0.5, 1.0,], [1.0, 0.5,]];
	private static var  R_THREE_STRAIGHT:Array<Array<Float>> = [[0.5, 1.5,], [1.5, 0.5,]];
	private static var  R_THREE_BENT:Array<Array<Float>> = [[1.0, 1.0,]];
	private static var  R_I:Array<Array<Float>> = [[2, 0.5,], [0.5, 2,]];
	private static var  R_L:Array<Array<Float>> = [[1.5, 1.0,], [1.0, 1.5,]];
	private static var  R_J:Array<Array<Float>> = [[1.5, 1.0,], [1.0, 1.5,]];
	private static var  R_T:Array<Array<Float>> = [[1.5, 1.0,], [1.0, 1.5,]];
	private static var  R_S:Array<Array<Float>> = [[1.0, 1.5,], [1.5, 1.0,]];
	private static var  R_Z:Array<Array<Float>> = [[1.0, 1.5,], [1.5, 1.0,]];
	private static var  R_O:Array<Array<Float>> = [[1.0, 1.0,]];
	
	
	public static var PIECES:Array<Array<Array<Int>>> = [
	ONE, ONE, 
	TWO, TWO, 
	THREE_STRAIGHT, THREE_STRAIGHT, 
	THREE_BENT, THREE_BENT, 
	I,
	L,
	J,
	T,
	S,
	Z,
	O,
	];
	
	
	public static var CENTERS:Array<Array<Array<Float>>> = [
	R_ONE, R_ONE, 
	R_TWO, R_TWO, 
	R_THREE_STRAIGHT, R_THREE_STRAIGHT, 
	R_THREE_BENT, R_THREE_BENT, 
	R_I,
	R_L,
	R_J,
	R_T,
	R_S,
	R_Z,
	R_O,
	];
	
	
	
}