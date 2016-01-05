package net.rezmason.hypertype.core;

import lime.graphics.Image;
import net.rezmason.gl.GLSystem;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.RenderTargetTexture;
import net.rezmason.gl.Texture;
import net.rezmason.gl.ViewportRenderTarget;
import net.rezmason.hypertype.core.CombineRenderMethod;
import net.rezmason.utils.santa.Present;
#if debug_graphics 
    import lime.graphics.cairo.CairoImageSurface;
    import net.rezmason.gl.ImageTexture;
#end

class Compositor {

    public var inputRenderTarget(default, null):RenderTarget;
    var inputTexture:RenderTargetTexture;
    #if debug_graphics 
        var debugTexture:ImageTexture;
        var debugSurface:CairoImageSurface;
        public var debugGraphics(default, null):DebugGraphics;
    #end
    var addedTextures:Array<Texture>;
    var debugTextures:Array<Texture>;
    var viewport:ViewportRenderTarget;
    var glSys:GLSystem;
    var renderMethod:CombineRenderMethod;
    public function new() {
        addedTextures = [];
        debugTextures = [];
        glSys = new Present(GLSystem);
        inputTexture = glSys.createRenderTargetTexture(FLOAT);
        inputRenderTarget = inputTexture.renderTarget;
        addedTextures.push(inputTexture);
        viewport = glSys.viewportRenderTarget;
        renderMethod = new CombineRenderMethod();
        #if debug_graphics 
            debugTexture = glSys.createImageTexture(new Image(null, 0, 0, 1, 1, 0x00000000));
            debugTextures.push(debugTexture);
            debugSurface = CairoImageSurface.fromImage(debugTexture.image);
            debugGraphics = new DebugGraphics(debugSurface);
        #end
    }

    public function setSize(width, height) {
        inputTexture.resize(width, height);
        #if debug_graphics 
            debugTexture.image.resize(width, height);
            debugSurface = CairoImageSurface.fromImage(debugTexture.image);
            @:privateAccess debugGraphics.recreate(debugSurface);
            debugGraphics.identityMatrix();
            if (width > height) {
                debugGraphics.translate((width - height) / 2, 0);
                debugGraphics.scale(height, height);
            } else {
                debugGraphics.translate(0, (height - width) / 2);
                debugGraphics.scale(width, width);
            }
            debugGraphics.translate(0.5, 0.5);
        #end
        viewport.resize(width, height);
    }

    public function draw() {
        #if debug_graphics
            var rect = debugTexture.image.rect;
            rect.x = Math.random() * rect.width;
            rect.y = Math.random() * rect.height;
            rect.width = 10;
            rect.height = 10;
            debugTexture.image.fillRect(rect, Std.random(0xFFFFFF) << 8 | 0x80);
            debugTexture.update();
        #end
        
        renderMethod.start(viewport);
        renderMethod.drawScreen(addedTextures, debugTextures);
        renderMethod.end();
    }
}
