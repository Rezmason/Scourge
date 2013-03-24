package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.utils.DrawUtil;

class Renderer {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;

    public var mouseView(default, null):MouseView;

    var drawUtil:DrawUtil;
    var activeStyle:Style;
    var aspectRatio:Float;

    public function new(drawUtil:DrawUtil) {
        this.drawUtil = drawUtil;
        mouseView = new MouseView(0.2);
        aspectRatio = 1;
    }

    public function setSize(width:Int, height:Int):Void {
        drawUtil.resize(width, height);
        mouseView.configure(width, height);
        aspectRatio = width / height;
    }

    public function render(scene:Scene, style:Style, mode:RenderMode):Void {

        if (activeStyle != style) {
            if (activeStyle != null) activeStyle.deactivate();
            activeStyle = style;
            activeStyle.activate();
        }

        drawUtil.clear(style.backgroundColor);

        for (model in scene.models) {
            if (model.numGlyphs == 0) continue;
            drawUtil.setScissorRectangle(model.scissorRectangle);
            style.setMatrices(scene.cameraMat, model.matrix);
            style.setGlyphTexture(model.glyphTexture, aspectRatio);

            for (segment in model.segments) {
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
