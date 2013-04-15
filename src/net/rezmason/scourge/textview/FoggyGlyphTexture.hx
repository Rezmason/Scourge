package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
import nme.filters.BitmapFilterQuality;
import nme.filters.GlowFilter;

import net.rezmason.scourge.textview.core.GlyphTexture;

class FoggyGlyphTexture extends GlyphTexture {

    override function customize(src:BitmapData):BitmapData {
        var bmd:BitmapData = new BitmapData(src.width, src.height, true, 0x0);

        bmd.applyFilter(src, src.rect, src.rect.topLeft,
            new GlowFilter(
                0xFF000000,
                1.0,
                5,
                5,
                1,
                BitmapFilterQuality.HIGH,
                true
            )
        );

        //bmd = src.clone();

        return bmd;
    }
}
