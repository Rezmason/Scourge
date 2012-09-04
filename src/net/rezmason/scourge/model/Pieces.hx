package net.rezmason.scourge.model;

import haxe.Resource;

import net.rezmason.scourge.model.PieceTypes;

using haxe.Json;

class Pieces {
    public static var groups:Array<PieceGroup> = Resource.getString("pieces").parse();
}
