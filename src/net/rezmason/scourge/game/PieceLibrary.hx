package net.rezmason.scourge.game;

import net.rezmason.scourge.game.Piece;

using haxe.Json;

class PieceLibrary {

    var piecesBySize:Array<Array<Piece>>;
    var piecesByID:Map<String, Piece>;

    public function new(json:String):Void {
        if (json == null) throw "Null JSON.";
        var data:Array<Array<PieceData>> = json.parse();
        piecesBySize = [];
        piecesByID = new Map();

        for (dataSeries in data) {
            var pieceSeries = [];
            piecesBySize.push(pieceSeries);
            for (datum in dataSeries) {
                var piece = new Piece(datum);
                pieceSeries.push(piece);
                piecesByID[piece.id] = piece;
            }
        }
    }

    public inline function maxSize():Int return piecesBySize.length;
    public inline function getPieceByID(id:String):Piece return piecesByID[id];
    public inline function getPieceBySizeAndIndex(size:Int, index:Int):Piece return piecesBySize[size][index];
    public inline function getNumPiecesOfSize(size:Int):Int return piecesBySize[size].length;
    public inline function getPiecesOfSize(size:Int):Array<Piece> return piecesBySize[size].copy();
}
