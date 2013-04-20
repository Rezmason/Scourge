package net.rezmason.scourge.textview.core;

import net.rezmason.scourge.textview.utils.DrawUtil;

class Renderer {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;

    public var mouseView(default, null):MouseView;

    var drawUtil:DrawUtil;
    var activeStyle:Style;

    public function new(drawUtil:DrawUtil) {
        this.drawUtil = drawUtil;
        mouseView = new MouseView(0.2);
    }

    public function setSize(width:Int, height:Int):Void {
        drawUtil.resize(width, height);
        mouseView.configure(width, height);
    }

    public function render(bodies:Array<Body>, style:Style, mode:RenderMode, clear:Bool = true):Void {

        if (activeStyle != style) {
            if (activeStyle != null) activeStyle.deactivate();
            activeStyle = style;
            activeStyle.activate();
        }

        drawUtil.clear(style.backgroundColor);

        for (body in bodies) {
            if (body.numGlyphs == 0) continue;
            drawUtil.setScissorRectangle(body.scissorRectangle);
            style.setMatrices(body.camera, body.transform);
            style.setGlyphTexture(body.glyphTexture, body.glyphTransform);

            for (segment in body.segments) {
                style.setSegment(segment);
                drawUtil.drawTriangles(segment.indexBuffer, 0, segment.numVisibleGlyphs * Almanac.TRIANGLES_PER_GLYPH);
            }
        }

        switch (mode) {
            case SCREEN: drawUtil.present();
            case MOUSE:  drawUtil.drawToBitmapData(mouseView.bitmapData);
        }
    }
}
