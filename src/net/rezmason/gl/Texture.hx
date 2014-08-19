package net.rezmason.gl;

import flash.display.BitmapData;

typedef NativeTexture = #if flash flash.display3D.textures.TextureBase #else openfl.gl.GLTexture #end;

enum Texture {
    BMD(bmd:BitmapData);
    TEX(tex:NativeTexture);
}
