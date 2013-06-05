package net.rezmason.gl;

import flash.display.BitmapData;

abstract Texture(BitmapData) {
    inline function new(bd:BitmapData):Void this = bd;
    @:from static public inline function fromBitmapData(bd:BitmapData):Texture return new Texture(bd);
}
