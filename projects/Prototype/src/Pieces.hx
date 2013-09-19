package;

typedef PieceDef = Array<Array<Int>>;
typedef NeighborDef = Array<Array<Int>>;
typedef PieceRotationDef = Array<Array<Float>>;

class Pieces {

	public static var ORIGIN_X:Int = 1;
	public static var ORIGIN_Y:Int = 1;

	public static var O_PIECE:Array<Int> = [ 0, 0, 0, 1, 1, 0, 1, 1, ];

	// the x,y ooordinates of the blocks in each orientation of each piece
	private static var  ONE:PieceDef = [ [ 0, 0, ], ];
	private static var  TWO:PieceDef = [ [ 0, 0, 0, 1, ], [ 0, 0, 1, 0, ], ];
	private static var  THREE_STRAIGHT:PieceDef = [ [ 0, 0, 0, 1, 0, 2, ], [ 0, 0, 1, 0, 2, 0, ], ];
	private static var  THREE_BENT:PieceDef = [ [ 0, 0, 0, 1, 1, 0, ], [ 0, 0, 0, 1, 1, 1, ], [ 0, 1, 1, 0, 1, 1, ], [ 0, 0, 1, 0, 1, 1, ], ];
	private static var  I:PieceDef = [ [ 0, 0, 1, 0, 2, 0, 3, 0, ], [ 0, 0, 0, 1, 0, 2, 0, 3, ], ];
	private static var  L:PieceDef = [ [ 0, 0, 1, 0, 2, 0, 2, 1, ], [ 0, 0, 0, 1, 0, 2, 1, 0, ], [ 0, 0, 0, 1, 1, 1, 2, 1, ], [ 0, 2, 1, 0, 1, 1, 1, 2, ], ];
	private static var  J:PieceDef = [ [ 0, 1, 1, 1, 2, 0, 2, 1, ], [ 0, 0, 1, 0, 1, 1, 1, 2, ], [ 0, 0, 0, 1, 1, 0, 2, 0, ], [ 0, 0, 0, 1, 0, 2, 1, 2, ], ];
	private static var  T:PieceDef = [ [ 0, 0, 1, 0, 1, 1, 2, 0, ], [ 0, 0, 0, 1, 0, 2, 1, 1, ], [ 0, 1, 1, 0, 1, 1, 2, 1, ], [ 0, 1, 1, 0, 1, 1, 1, 2, ], ];
	private static var  S:PieceDef = [ [ 0, 1, 0, 2, 1, 0, 1, 1, ], [ 0, 0, 1, 0, 1, 1, 2, 1, ], ];
	private static var  Z:PieceDef = [ [ 0, 0, 0, 1, 1, 1, 1, 2, ], [ 0, 1, 1, 0, 1, 1, 2, 0, ], ];
	private static var  O:PieceDef = [ O_PIECE, ];

	// the x,y coordinates of the center of rotation of each piece
	private static var  R_ONE:PieceRotationDef = [ [ 0.5, 0.5, ], ];
	private static var  R_TWO:PieceRotationDef = [ [ 0.5, 1.0, ], [ 1.0, 0.5, ], ];
	private static var  R_THREE_STRAIGHT:PieceRotationDef = [ [ 0.5, 1.5, ], [ 1.5, 0.5, ], ];
	private static var  R_THREE_BENT:PieceRotationDef = [ [ 1.0, 1.0, ], ];
	private static var  R_I:PieceRotationDef = [ [ 2, 0.5, ], [ 0.5, 2, ], ];
	private static var  R_L:PieceRotationDef = [ [ 1.5, 1.0, ], [ 1.0, 1.5, ], ];
	private static var  R_J:PieceRotationDef = [ [ 1.5, 1.0, ], [ 1.0, 1.5, ], ];
	private static var  R_T:PieceRotationDef = [ [ 1.5, 1.0, ], [ 1.0, 1.5, ], ];
	private static var  R_S:PieceRotationDef = [ [ 1.0, 1.5, ], [ 1.5, 1.0, ], ];
	private static var  R_Z:PieceRotationDef = [ [ 1.0, 1.5, ], [ 1.5, 1.0, ], ];
	private static var  R_O:PieceRotationDef = [ [ 1.0, 1.0, ], ];

	// the x,y coordinates of the blocks adjacent to each piece
	private static var  N_ONE:NeighborDef = [ [ -1, 0, 1, 0, 0, -1, 0, 1, ], ];
	private static var  N_TWO:NeighborDef = [ [ -1, 0, 1, 0, 0, -1, -1, 1, 1, 1, 0, 2, ], [ -1, 0, 0, -1, 0, 1, 2, 0, 1, -1, 1, 1, ], ];
	private static var  N_THREE_STRAIGHT:NeighborDef = [ [ -1, 0, 1, 0, 0, -1, -1, 1, 1, 1, -1, 2, 1, 2, 0, 3, ], [ -1, 0, 0, -1, 0, 1, 1, -1, 1, 1, 3, 0, 2, -1, 2, 1, ], ];
	private static var  N_THREE_BENT:NeighborDef = [ [ -1, 0, 0, -1, -1, 1, 1, 1, 0, 2, 2, 0, 1, -1, ], [ -1, 0, 1, 0, 0, -1, -1, 1, 0, 2, 2, 1, 1, 2, ], [ -1, 1, 0, 0, 0, 2, 2, 0, 1, -1, 2, 1, 1, 2, ], [ -1, 0, 0, -1, 0, 1, 2, 0, 1, -1, 2, 1, 1, 2, ], ];
	private static var  N_I:NeighborDef = [ [ -1, 0, 0, -1, 0, 1, 1, -1, 1, 1, 2, -1, 2, 1, 4, 0, 3, -1, 3, 1, ], [ -1, 0, 1, 0, 0, -1, -1, 1, 1, 1, -1, 2, 1, 2, -1, 3, 1, 3, 0, 4, ], ];
	private static var  N_L:NeighborDef = [ [ -1, 0, 0, -1, 0, 1, 1, -1, 1, 1, 3, 0, 2, -1, 3, 1, 2, 2, ], [ -1, 0, 0, -1, -1, 1, 1, 1, -1, 2, 1, 2, 0, 3, 2, 0, 1, -1, ], [ -1, 0, 1, 0, 0, -1, -1, 1, 0, 2, 1, 2, 3, 1, 2, 0, 2, 2, ], [ -1, 2, 0, 1, 0, 3, 0, 0, 2, 0, 1, -1, 2, 1, 2, 2, 1, 3, ], ];
	private static var  N_J:NeighborDef = [ [ -1, 1, 0, 0, 0, 2, 1, 0, 1, 2, 3, 0, 2, -1, 3, 1, 2, 2, ], [ -1, 0, 0, -1, 0, 1, 2, 0, 1, -1, 2, 1, 0, 2, 2, 2, 1, 3, ], [ -1, 0, 0, -1, -1, 1, 1, 1, 0, 2, 1, -1, 3, 0, 2, -1, 2, 1, ], [ -1, 0, 1, 0, 0, -1, -1, 1, 1, 1, -1, 2, 0, 3, 2, 2, 1, 3, ], ];
	private static var  N_T:NeighborDef = [ [ -1, 0, 0, -1, 0, 1, 1, -1, 2, 1, 1, 2, 3, 0, 2, -1, ], [ -1, 0, 1, 0, 0, -1, -1, 1, -1, 2, 1, 2, 0, 3, 2, 1, ], [ -1, 1, 0, 0, 0, 2, 2, 0, 1, -1, 1, 2, 3, 1, 2, 2, ], [ -1, 1, 0, 0, 0, 2, 2, 0, 1, -1, 2, 1, 2, 2, 1, 3, ], ];
	private static var  N_S:NeighborDef = [ [ -1, 1, 0, 0, -1, 2, 1, 2, 0, 3, 2, 0, 1, -1, 2, 1, ], [ -1, 0, 0, -1, 0, 1, 2, 0, 1, -1, 1, 2, 3, 1, 2, 2, ], ];
	private static var  N_Z:NeighborDef = [ [ -1, 0, 1, 0, 0, -1, -1, 1, 0, 2, 2, 1, 2, 2, 1, 3, ], [ -1, 1, 0, 0, 0, 2, 1, -1, 2, 1, 1, 2, 3, 0, 2, -1, ], ];
	private static var  N_O:NeighborDef = [ [ -1, 0, 0, -1, -1, 1, 0, 2, 2, 0, 1, -1, 2, 1, 1, 2, ], ];

	public static var PIECES:Array<PieceDef> = [
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


	public static var CENTERS:Array<PieceRotationDef> = [
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


	public static var NEIGHBORS:Array<NeighborDef> = [
		N_ONE, N_ONE,
		N_TWO, N_TWO,
		N_THREE_STRAIGHT, N_THREE_STRAIGHT,
		N_THREE_BENT, N_THREE_BENT,
		N_I,
		N_L,
		N_J,
		N_T,
		N_S,
		N_Z,
		N_O,
	];


}
