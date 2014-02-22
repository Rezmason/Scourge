package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import flash.geom.Matrix3D;
import net.rezmason.utils.display.FlatFont;
import net.rezmason.gl.Texture;
import net.rezmason.gl.utils.TextureUtil;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var font(default, null):FlatFont;
    public var matrix(default, null):Matrix3D;
    public var aspectRatio(default, null):Float;

    public function new(textureUtil:TextureUtil, font:FlatFont):Void {
        this.font = font;
        var bmp:BitmapData = font.getBitmapDataClone();
        texture = textureUtil.createTexture(customize(bmp));

        #if flash
            bmp.dispose();
        #end

        matrix = new Matrix3D();
        matrix.appendTranslation(-0.5, -0.5, 0);
    }

    function customize(src:BitmapData):BitmapData { return src; }
}
