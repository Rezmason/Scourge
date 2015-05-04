package net.rezmason.scourge.game;

import net.rezmason.scourge.game.PieceTypes;

using haxe.Json;

class Pieces {

    private var freePiecesBySize:Array<Array<FreePiece>>;
    private var freePiecesById:Array<FreePiece>;
    private var pieceIdsBySize:Array<Array<Int>>;

    public function new(json:String):Void {
        if (json == null) throw "Null JSON.";
        var data:Array<Array<Dynamic>> = json.parse();
        freePiecesBySize = [for (series in data) [for (datum in series) new FreePiece(datum)]];
        freePiecesById = [];
        pieceIdsBySize = [for (series in freePiecesBySize) [for (freePiece in series) freePiecesById.push(freePiece) - 1]];
    }

    public inline function maxSize():Int return freePiecesBySize.length;
    public inline function getPieceById(id:Int):FreePiece return freePiecesById[id];
    public inline function getPieceBySizeAndIndex(size:Int, index:Int):FreePiece return freePiecesBySize[size][index];
    public inline function getPieceIdBySizeAndIndex(size:Int, index:Int):Int return freePiecesById.indexOf(freePiecesBySize[size][index]);
    public inline function getNumPiecesBySize(size:Int):Int return pieceIdsBySize[size].length;
    public inline function getPieceId(piece:FreePiece):Int return freePiecesById.indexOf(piece);
    public inline function getAllPiecesOfSize(size:Int):Array<FreePiece> return freePiecesBySize[size].copy();

    public inline function getAllPieceIDsOfSize(size:Int):Array<Int> {
        var ids:Array<Int> = [];
        for (piece in getAllPiecesOfSize(size)) ids.push(freePiecesById.indexOf(piece));
        return ids;
    }
}
