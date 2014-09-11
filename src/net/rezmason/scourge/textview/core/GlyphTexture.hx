package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import net.rezmason.utils.display.FlatFont;
import net.rezmason.gl.Texture;
import net.rezmason.gl.GLSystem;
import net.rezmason.utils.santa.Present;

class GlyphTexture {

    public var texture(default, null):Texture;
    public var font(default, null):FlatFont;
    public var aspectRatio(default, null):Float;
    public var name(default, null):String;

    public function new(name:String, font:FlatFont):Void {
        this.name = name;
        this.font = font;
        var bmp:BitmapData = font.getBitmapDataClone();
        var util:GLSystem = new Present(GLSystem);
        texture = util.createBitmapDataTexture(bmp);

        #if flash
            bmp.dispose();
        #end
    }
}
