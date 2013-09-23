package net.rezmason.scourge.textview.core;

import net.rezmason.gl.utils.DrawUtil;
import net.rezmason.gl.OutputBuffer;

class Renderer {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;

    var drawUtil:DrawUtil;
    var activeMethod:RenderMethod;

    public function new(drawUtil:DrawUtil) {
        this.drawUtil = drawUtil;
    }

    public function render(bodies:Array<Body>, method:RenderMethod, outputBuffer:OutputBuffer):Void {

        if (method == null) {
            trace('Null method.');
            return;
        }

        if (activeMethod != method) {
            if (activeMethod != null) activeMethod.deactivate();
            activeMethod = method;
            activeMethod.activate();
        }

        drawUtil.setOutputBuffer(outputBuffer);
        drawUtil.clear(method.backgroundColor);

        for (body in bodies) {
            if (body.numGlyphs == 0) continue;
            method.setMatrices(body.camera, body.transform);
            method.setGlyphTexture(body.glyphTexture, body.glyphTransform);

            for (segment in body.segments) {
                method.setSegment(segment);
                drawUtil.drawTriangles(segment.indexBuffer, 0, segment.numGlyphs * Almanac.TRIANGLES_PER_GLYPH);
            }
        }

        drawUtil.finishOutputBuffer(outputBuffer);
    }
}
