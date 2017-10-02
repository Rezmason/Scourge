package net.rezmason.hypertype.core;

import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.Program;
import net.rezmason.gl.RenderTarget;
import net.rezmason.math.Vec4;

class RenderMethod {

    public var backgroundColor(default, null):Vec4;
    var program:Program;
    var vertShader:String;
    var fragShader:String;
    var extensions:Array<String>;

    function new():Void {
        backgroundColor = new Vec4(0, 0, 0, 1);
        extensions = [];
        composeShaders();
        program = new Program(vertShader, fragShader, extensions);
    }

    public function start(renderTarget:RenderTarget, params:Map<String, Any>):Void {
        program.use();
        program.setRenderTarget(renderTarget);
        program.clear(backgroundColor);
    }

    public function end():Void {}
    function composeShaders():Void {}
    function makeVertexShader():String return '';
    function makeFragmentShader():String return '';
}

