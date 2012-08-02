package net.rezmason.scourge.model;

typedef IntCoord = {x:Int, y:Int};
typedef Piece = Array<IntCoord>;
typedef Pattern = Array<Array<Bool>>;

typedef PatternFunction = Int->Array<Pattern>;

class PieceGenerator {

    private static var MONOMINO:Pattern = [[true]];

    private static var fixedPatternsBySize:Array<Array<Pattern>> = [];
    private static var oneSidedPatternsBySize:Array<Array<Pattern>> = [];
    private static var freePatternsBySize:Array<Array<Pattern>> = [];

    private static var patterns:Array<Array<Array<Pattern>>> = [freePatternsBySize, oneSidedPatternsBySize, fixedPatternsBySize];

    private static var fixedPiecesBySize:Array<Array<Piece>> = [];
    private static var oneSidedPiecesBySize:Array<Array<Piece>> = [];
    private static var freePiecesBySize:Array<Array<Piece>> = [];

    private static var pieces:Array<Array<Array<Piece>>> = [fixedPiecesBySize, oneSidedPiecesBySize, freePiecesBySize];

    private static var patternFunctions:Array<PatternFunction> = [makeFixedPatterns, makeOneSidedPatterns, makeFreePatterns];

    public static function generate(size:Int, type:Int):Array<Piece> {
        if (size < 0 || type < 0 || type > PieceType.FREE) throw "Invalid generator input";
        var pieceSet:Array<Array<Piece>> = pieces[type];
        if (pieceSet[size] == null) pieceSet[size] = makePieces(size, type);
        return pieceSet[size];
    }

    private static function makePieces(size:Int, type:Int):Array<Piece> {
        var patternSet:Array<Array<Pattern>> = patterns[type];
        if (patternSet[size] == null) patternSet[size] = patternFunctions[type](size);
        var pieces:Array<Piece> = [];
        for (pattern in patternSet[size]) pieces.push(patternToPiece(pattern));
        return pieces;
    }

    private static function makeFreePatterns(size:Int):Array<Pattern> {

        return [];
    }

    private static function makeOneSidedPatterns(size:Int):Array<Pattern> {

        return [];
    }

    private static function makeFixedPatterns(size:Int):Array<Pattern> {

        return [];
    }

    private static function patternToPiece(pattern:Pattern):Piece {
        var piece:Piece = [];
        for (y in 0...pattern.length) for (x in 0...pattern[y].length) if (pattern[y][x]) piece.push({x:x, y:y});
        return piece;
    }
}

class PieceType {
    public inline static var FREE:Int = 0;
    public inline static var ONE_SIDED:Int = 1;
    public inline static var FIXED:Int = 2;
}
