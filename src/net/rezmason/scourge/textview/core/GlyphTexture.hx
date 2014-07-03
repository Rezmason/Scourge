package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import net.rezmason.utils.display.FlatFont;
import net.rezmason.gl.Texture;
import net.rezmason.gl.utils.TextureUtil;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var font(default, null):FlatFont;
    public var aspectRatio(default, null):Float;

    public function new(textureUtil:TextureUtil, font:FlatFont):Void {
        this.font = font;
        var bmp:BitmapData = font.getBitmapDataClone();
        texture = textureUtil.createTexture(customize(bmp));

        #if flash
            bmp.dispose();
        #end
    }

    function customize(src:BitmapData):BitmapData { return src; }
}
