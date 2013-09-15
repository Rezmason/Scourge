package net.rezmason.scourge.textview;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.filters.BitmapFilterQuality;
import flash.filters.BlurFilter;
import flash.geom.ColorTransform;

import net.rezmason.scourge.textview.core.GlyphTexture;

class FoggyGlyphTexture extends GlyphTexture {

    override function customize(src:BitmapData):BitmapData {
        var bmd:BitmapData = new BitmapData(src.width, src.height, false, 0x0);
        bmd.applyFilter(src, src.rect, src.rect.topLeft, new BlurFilter( 7, 7, BitmapFilterQuality.HIGH ));
        bmd.draw(src, null, null, BlendMode.MULTIPLY);
        bmd.colorTransform(bmd.rect, new ColorTransform(1.5, 1.5, 1.5));
        //bmd = src.clone();

        return bmd;
    }
}
