package net.rezmason.hypertype.core;

class SceneRenderMethod extends RenderMethod {

    override public function finish():Void {
        setSegment(null);
        super.finish();
    }

    public function drawScene(scene:Scene) {
        for (body in scene.bodies) {
            if (body.numGlyphs > 0 && shouldDrawBody(body)) {
                body.upload();
                drawBody(body);
            }
        }
    }

    function drawBody(body:Body):Void {
        for (segment in body.segments) {
            setSegment(segment);
            glSys.draw(segment.indexBuffer, 0, segment.numGlyphs * Almanac.TRIANGLES_PER_GLYPH);
        }
    }

    function shouldDrawBody(body:Body) return true;
    function setSegment(segment:BodySegment):Void {}
}
