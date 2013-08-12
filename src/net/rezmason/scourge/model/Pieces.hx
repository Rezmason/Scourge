package net.rezmason.scourge.model;

import net.rezmason.scourge.model.PieceTypes;

using Lambda;
using haxe.JSON;

class Pieces {

    private var pieceGroupsBySize:Array<Array<PieceGroup>>;
    private var pieceGroupsById:Array<PieceGroup>;
    private var pieceIdsBySize:Array<Array<Int>>;

    public function new(json:String):Void {
        if (json == null) throw "Null JSON.";
        pieceGroupsBySize = json.parse();
        pieceGroupsById = [];
        pieceIdsBySize = pieceGroupsToIds();
    }

    private inline function pieceGroupsToIds():Array<Array<Int>> {
        var arr:Array<Array<Int>> = [];
        for (groups in pieceGroupsBySize) {
            var ids:Array<Int> = [];
            arr.push(ids);
            for (group in groups) ids.push(pieceGroupsById.push(group) - 1);
        }
        return arr;
    }

    public inline function getPieceById(id:Int):PieceGroup { return pieceGroupsById[id]; }
    public inline function getPieceBySizeAndIndex(size:Int, index:Int):PieceGroup { return pieceGroupsBySize[size - 1][index]; }
    public inline function getPieceIdBySizeAndIndex(size:Int, index:Int):Int { return pieceGroupsById.indexOf(pieceGroupsBySize[size - 1][index]); }
    public inline function getNumPiecesBySize(size:Int):Int { return pieceIdsBySize[size - 1].length; }
    public inline function getPieceId(piece:PieceGroup):Int { return pieceGroupsById.indexOf(piece); }
    public inline function getAllPiecesOfSize(size:Int):Array<PieceGroup> { return pieceGroupsBySize[size - 1].copy(); }

    public inline function getAllPieceIDsOfSize(size:Int):Array<Int> {
        var ids:Array<Int> = [];
        for (piece in getAllPiecesOfSize(size)) ids.push(pieceGroupsById.indexOf(piece));
        return ids;
    }
}
