package net.rezmason.hypertype.core;

class SceneRenderMethod extends RenderMethod {

    override public function end():Void {
        super.end();
        setGlyphBatch(null);
    }

    public function drawScene(stage:Stage) {
        for (body in stage.bodies) {
            if (body.size > 0 && shouldDrawBody(body)) {
                body.upload();
                drawBody(body);
            }
        }
    }

    function drawBody(body:Body):Void {
        for (batch in body.glyphBatches) {
            setGlyphBatch(batch);
            program.draw(batch.indexBuffer, 0, batch.size * Almanac.TRIANGLES_PER_GLYPH);
        }
    }

    function shouldDrawBody(body:Body) return true;
    function setGlyphBatch(batch:GlyphBatch):Void {}
}
