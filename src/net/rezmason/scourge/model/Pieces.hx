package net.rezmason.scourge.model;

import haxe.Resource;

import net.rezmason.scourge.model.PieceTypes;

using Lambda;
using haxe.Json;

class Pieces {
    private static var pieceGroupsBySize:Array<Array<PieceGroup>> = Resource.getString("pieces").parse();

    private static var pieceGroupsById:Array<PieceGroup> = [];
    private static var pieceIdsBySize:Array<Array<Int>> = pieceGroupsToIds();

    private inline static function pieceGroupsToIds():Array<Array<Int>> {
        var arr:Array<Array<Int>> = [];
        for (groups in pieceGroupsBySize) {
            var ids:Array<Int> = [];
            arr.push(ids);
            for (group in groups) ids.push(pieceGroupsById.push(group) - 1);
        }
        return arr;
    }

    public inline static function getPieceById(id:Int):PieceGroup { return pieceGroupsById[id]; }
    public inline static function getPieceBySizeAndIndex(size:Int, index:Int):PieceGroup { return pieceGroupsBySize[size - 1][index]; }
    public inline static function getPieceIdBySizeAndIndex(size:Int, index:Int):Int { return pieceGroupsById.indexOf(pieceGroupsBySize[size - 1][index]); }
    public inline static function getNumPiecesBySize(size:Int):Int { return pieceIdsBySize[size - 1].length; }
    public inline static function getPieceId(piece:PieceGroup):Int { return pieceGroupsById.indexOf(piece); }
    public inline static function getAllPiecesOfSize(size:Int):Array<PieceGroup> { return pieceGroupsBySize[size - 1].copy(); }

    public inline static function getAllPieceIDsOfSize(size:Int):Array<Int> {
        var ids:Array<Int> = [];
        for (piece in getAllPiecesOfSize(size)) ids.push(pieceGroupsById.indexOf(piece));
        return ids;
    }
}
