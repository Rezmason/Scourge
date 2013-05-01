package net.rezmason.scourge.textview.core;

import net.rezmason.scourge.textview.utils.DrawUtil;

class Renderer {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;

    public var mouseView(default, null):MouseView;

    var drawUtil:DrawUtil;
    var activeMethod:RenderMethod;

    public function new(drawUtil:DrawUtil) {
        this.drawUtil = drawUtil;
        mouseView = new MouseView(0.2);
    }

    public function setSize(width:Int, height:Int):Void {
        drawUtil.resize(width, height);
        mouseView.configure(width, height);
    }

    public function render(bodies:Array<Body>, method:RenderMethod, dest:RenderDestination, clear:Bool = true):Void {

        if (activeMethod != method) {
            if (activeMethod != null) activeMethod.deactivate();
            activeMethod = method;
            activeMethod.activate();
        }

        drawUtil.clear(method.backgroundColor);

        for (body in bodies) {
            if (body.numGlyphs == 0) continue;
            drawUtil.setScissorRectangle(body.scissorRectangle);
            method.setMatrices(body.camera, body.transform);
            method.setGlyphTexture(body.glyphTexture, body.glyphTransform);

            for (segment in body.segments) {
                method.setSegment(segment);
                drawUtil.drawTriangles(segment.indexBuffer, 0, segment.numVisibleGlyphs * Almanac.TRIANGLES_PER_GLYPH);
            }
        }

        switch (dest) {
            case SCREEN: drawUtil.present();
            case MOUSE:  drawUtil.drawToBitmapData(mouseView.bitmapData);
        }
    }
}
