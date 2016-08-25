package net.rezmason.scourge.lab;

import net.rezmason.gl.DataType;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.RenderTargetTexture;
import net.rezmason.gl.ViewportRenderTarget;

class Lab {
    var width:UInt;
    var height:UInt;
    
    public var outputTexture(default, null):RenderTargetTexture;
    public var renderTarget(default, null):RenderTarget;
    
    public function new(width:UInt, height:UInt, ?outputType:DataType):Void {
        this.width = width;
        this.height = height;
        if (outputType != null) {
            outputTexture = new RenderTargetTexture(outputType);
            renderTarget = outputTexture.renderTarget;
            outputTexture.resize(width, height);
        } else {
            var viewportRT = new ViewportRenderTarget();
            viewportRT.resize(width, height);
            renderTarget = viewportRT;
        }
        init();
    }

    function init():Void {}
    function update():Void {}
    function draw():Void {}

    public function render():Void {
        update();
        draw();
    }
}
