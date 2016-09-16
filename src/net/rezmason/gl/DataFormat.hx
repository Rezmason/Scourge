package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract DataFormat(Int) to Int {
    var SINGLE_CHANNEL_FLOAT = #if desktop 0x822E /*R32F*/ #else GL.LUMINANCE #end ;
    var RGBA_FLOAT = #if desktop 0x8814 /*RGBA32F*/ #else GL.RGBA #end ;
    var SINGLE_CHANNEL_HALF_FLOAT = #if desktop 0x822D /*R16F*/ #else GL.LUMINANCE #end ;
    var RGBA_HALF_FLOAT = #if desktop 0x881A /*RGBA16F*/ #else GL.RGBA #end ;
    var SINGLE_CHANNEL_UNSIGNED_BYTE = #if desktop 0x1903 /*RED; might be incorrect*/ #else GL.LUMINANCE #end ;
    var RGBA_UNSIGNED_BYTE = GL.RGBA;
}
