package net.rezmason.hypertype.core;

import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.Program;
import net.rezmason.gl.RenderTarget;
import net.rezmason.math.Vec3;

class RenderMethod {

    public var backgroundColor(default, null):Vec3;
    public var backgroundAlpha:Float;
    var program:Program;
    var vertShader:String;
    var fragShader:String;
    var extensions:Array<String>;

    function new():Void {
        backgroundColor = new Vec3(0, 0, 0);
        backgroundAlpha = 1;
        extensions = [];
        composeShaders();
        program = new Program(vertShader, fragShader, extensions);
    }

    public function start(renderTarget:RenderTarget, args:Array<Dynamic>):Void {
        program.use();
        program.setRenderTarget(renderTarget);
        program.clear(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundAlpha);
    }

    public function end():Void {}
    function composeShaders():Void {}
    function makeVertexShader():String return '';
    function makeFragmentShader():String return '';
}

