package net.rezmason.scourge.textview.core;

import net.rezmason.scourge.textview.utils.DrawUtil;
import net.rezmason.scourge.textview.core.Types;

class Renderer {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;

    var width:Int;
    var height:Int;

    var mouseSystem:MouseSystem;
    var drawUtil:DrawUtil;
    var activeMethod:RenderMethod;

    public function new(drawUtil:DrawUtil, mouseSystem:MouseSystem) {
        this.drawUtil = drawUtil;
        this.mouseSystem = mouseSystem;
        width = -1;
        height = -1;
    }

    public function setSize(width:Int, height:Int):Void {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;
            drawUtil.resize(width, height);
        }
    }

    public function render(bodies:Array<Body>, method:RenderMethod, dest:RenderDestination):Void {

        if (method == null) {
            trace("Null method.");
            return;
        }

        if (activeMethod != method) {
            if (activeMethod != null) activeMethod.deactivate();
            activeMethod = method;
            activeMethod.activate();
        }

        drawUtil.clear(method.backgroundColor);

        for (body in bodies) {
            if (body.numGlyphs == 0) continue;
            method.setMatrices(body.camera, body.transform);
            method.setGlyphTexture(body.glyphTexture, body.glyphTransform);

            for (segment in body.segments) {
                method.setSegment(segment);
                drawUtil.drawTriangles(segment.indexBuffer, 0, segment.numVisibleGlyphs * Almanac.TRIANGLES_PER_GLYPH);
            }
        }

        switch (dest) {
            case SCREEN: drawUtil.present();
            case MOUSE:
                drawUtil.readBack(width, height, mouseSystem.data);
                mouseSystem.fartBD();
        }
    }
}
