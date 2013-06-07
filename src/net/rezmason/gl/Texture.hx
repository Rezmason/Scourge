package net.rezmason.gl;

import flash.display.BitmapData;

#if flash
    typedef Texture = flash.display3D.textures.Texture;
#else
    abstract Texture(BitmapData) {
        inline function new(bd:BitmapData):Void this = bd;
        @:from static public inline function fromBitmapData(bd:BitmapData):Texture return new Texture(bd);
    }
#end
