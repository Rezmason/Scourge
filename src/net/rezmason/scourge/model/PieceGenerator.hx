package net.rezmason.scourge.model;

typedef IntCoord = {x:Int, y:Int};
typedef Piece = Array<IntCoord>;
typedef Pattern = Array<Array<Bool>>;

typedef PatternFunction = Int->Array<Pattern>;

using Lambda;

class PieceGenerator {

    private static var MONOMINO:Pattern = [
        [false, false, false],
        [false,  true, false],
        [false, false, false],
    ];

    private static var fixedPatternsBySize:Array<Array<Pattern>> = [];
    private static var oneSidedPatternsBySize:Array<Array<Pattern>> = [];
    private static var freePatternsBySize:Array<Array<Pattern>> = [];

    private static var patterns:Array<Array<Array<Pattern>>> = [fixedPatternsBySize, oneSidedPatternsBySize, freePatternsBySize];

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

    private static function makeFixedPatterns(size:Int):Array<Pattern> {
        var patterns:Array<Pattern> = [];

        if (size == 1) {
            patterns.push(MONOMINO);
        } else {

            if (fixedPatternsBySize[size - 1] == null) fixedPatternsBySize[size - 1] = makeFixedPatterns(size - 1);
            var predecessors:Array<Pattern> = fixedPatternsBySize[size - 1];

            for (predecessor in predecessors) {

                // create modifications of the predecessor

                for (pattern in getProgeny(inflatePattern(predecessor))) {
                    patterns.push(pattern);
                }
            }

            if (patterns.length > 1) {

                // remove duplicates

                for (ike in 0...patterns.length) {
                    if (patterns[ike] == null) continue;
                    for (jen in ike + 1...patterns.length) {
                        if (patterns[jen] != null && arePatternsEqual(patterns[ike], patterns[jen])) patterns[jen] = null;
                    }
                }
            }

            while (patterns.has(null)) patterns.remove(null);
        }

        return patterns;
    }

    private static function makeOneSidedPatterns(size:Int):Array<Pattern> {
        if (fixedPatternsBySize[size] == null) fixedPatternsBySize[size] = makeFixedPatterns(size);
        var patterns:Array<Pattern> = fixedPatternsBySize[size].copy();

        if (patterns.length > 1) {

            // remove duplicates

            for (ike in 0...patterns.length) {
                if (patterns[ike] == null) continue;
                var  r90Pattern:Pattern = rotatePattern(patterns[ike]);
                var r180Pattern:Pattern = rotatePattern(r90Pattern);
                var r270Pattern:Pattern = rotatePattern(r180Pattern);
                for (jen in ike + 1...patterns.length) {
                    if (patterns[jen] != null) {
                        if (arePatternsEqual( r90Pattern, patterns[jen]) ||
                            arePatternsEqual(r180Pattern, patterns[jen]) ||
                            arePatternsEqual(r270Pattern, patterns[jen])) {
                            patterns[jen] = null;
                        }
                    }
                }
            }
        }

        while (patterns.has(null)) patterns.remove(null);

        return patterns;
    }

    private static function makeFreePatterns(size:Int):Array<Pattern> {
        if (oneSidedPatternsBySize[size] == null) oneSidedPatternsBySize[size] = makeOneSidedPatterns(size);
        var patterns:Array<Pattern> = oneSidedPatternsBySize[size].copy();

        if (patterns.length > 1) {

            // remove duplicates

            for (ike in 0...patterns.length) {
                if (patterns[ike] == null) continue;
                var flipPattern:Pattern = vFlipPattern(patterns[ike]);
                var  r90Pattern:Pattern = rotatePattern(flipPattern);
                var r180Pattern:Pattern = rotatePattern(r90Pattern);
                var r270Pattern:Pattern = rotatePattern(r180Pattern);

                for (jen in ike + 1...patterns.length) {
                    if (patterns[jen] != null) {
                        if (arePatternsEqual(flipPattern, patterns[jen]) ||
                            arePatternsEqual( r90Pattern, patterns[jen]) ||
                            arePatternsEqual(r180Pattern, patterns[jen]) ||
                            arePatternsEqual(r270Pattern, patterns[jen])) {
                            patterns[jen] = null;
                        }
                    }
                }
            }
        }

        while (patterns.has(null)) patterns.remove(null);

        return patterns;
    }

    private static function inflatePattern(pattern:Pattern):Pattern {
        pattern = copyPattern(pattern);
        for (row in pattern) row.unshift(false);
        pattern.push([]);
        pattern.unshift([]);
        return pattern;
    }

    private static function rotatePattern(pattern:Pattern):Pattern {
        var rotatedPattern:Pattern = [];
        for (row in 0...pattern.length) {
            rotatedPattern.push([]);
            for (col in 0...pattern.length) {
                rotatedPattern[row][col] = pattern[col][row] == true;
            }
            rotatedPattern[row].reverse();
        }
        return rotatedPattern;
    }

    private static function hFlipPattern(pattern:Pattern):Pattern {
        pattern = copyPattern(pattern);
        for (ike in 0...pattern.length) {
            var row:Array<Bool> = pattern[ike];
            var newRow:Array<Bool> = [];
            for (jen in 0...pattern.length) {
                newRow[jen] = row[pattern.length - 1 - jen];
            }
            pattern[ike] = newRow;
        }
        return pattern;
    }

    private static function vFlipPattern(pattern:Pattern):Pattern {
        pattern = copyPattern(pattern);
        pattern.reverse();
        return pattern;
    }

    private static function copyPattern(pattern:Pattern):Pattern {
        var copy:Pattern = [];
        for (row in pattern) copy.push(row.copy());
        return copy;
    }

    private static function getProgeny(pattern:Pattern):Array<Pattern> {
        var progeny:Array<Pattern> = [];

        for (y in 0...pattern.length) {
            for (x in 0...pattern.length) {
                if (pattern[y][x] != true) {

                    var valid:Bool = false;

                    if (pattern[y][x-1] || pattern[y][x+1]) {
                        valid = true;
                    } else if (pattern[y-1] != null && pattern[y-1][x]) {
                        valid = true;
                    } else if (pattern[y+1] != null && pattern[y+1][x]) {
                        valid = true;
                    }

                    if (valid) {
                        var child:Pattern = copyPattern(pattern);
                        child[y][x] = true;
                        progeny.push(child);
                    }
                }
            }
        }

        return progeny;
    }

    private static function arePatternsEqual(pattern1:Pattern, pattern2:Pattern):Bool {

        var minX1:Int = Std.int(pattern1.length / 2);
        var minY1:Int = Std.int(pattern1.length / 2);
        var minX2:Int = Std.int(pattern1.length / 2);
        var minY2:Int = Std.int(pattern1.length / 2);

        // find the closest corner of pattern1

        for (row in 0...pattern1.length) {
            var col:Int = pattern1[row].indexOf(true);
            if (col != -1) {
                if (minX1 > col) minX1 = col;
                if (minY1 > row) minY1 = row;
            }
        }

        // find the closest corner of pattern2

        for (row in 0...pattern2.length) {
            var col:Int = pattern2[row].indexOf(true);
            if (col != -1) {
                if (minX2 > col) minX2 = col;
                if (minY2 > row) minY2 = row;
            }
        }

        for (row in 0...pattern1.length) {
            var slice1:Array<Bool> = pattern1[row + minY1];
            var slice2:Array<Bool> = pattern2[row + minY2];

            if (slice1 == null || slice2 == null) return true;

            for (col in 0...slice1.length) {
                if ((slice1[col + minX1] == true) != (slice2[col + minX2] == true)) return false;
            }
        }
        return true;
    }

    private static function patternToPiece(pattern:Pattern):Piece {
        var piece:Piece = [];
        for (y in 0...pattern.length) for (x in 0...pattern[y].length) if (pattern[y][x]) piece.push({x:x, y:y});

        var minX:Int = Std.int(pattern.length / 2);
        var minY:Int = Std.int(pattern.length / 2);

        for (coord in piece) {
            if (minX > coord.x) minX = coord.x;
            if (minY > coord.y) minY = coord.y;
        }

        for (coord in piece) {
            coord.x -= minX;
            coord.y -= minY;
        }

        return piece;
    }

    private static function spitPattern(pattern:Pattern):String {
        var str:String = "\n";
        var size:Int = pattern.length;
        for (row in pattern) {
            str += "| ";
            for (column in 0...size) {
                str += row[column] ? "H " : ". ";
            }
            str += "| \n";
        }
        return str;
    }
}

class PieceType {
    public inline static var FIXED:Int = 0;
    public inline static var ONE_SIDED:Int = 1;
    public inline static var FREE:Int = 2;
}
