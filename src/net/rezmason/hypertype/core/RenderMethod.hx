package net.rezmason.hypertype.core;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.Program;
import net.rezmason.math.Vec3;
import net.rezmason.utils.santa.Present;

class RenderMethod {

    public var backgroundColor(default, null):Vec3;
    public var backgroundAlpha:Float;
    var program:Program;
    var glSys:GLSystem;
    var vertShader:String;
    var fragShader:String;

    function new():Void {
        backgroundColor = new Vec3(0, 0, 0);
        backgroundAlpha = 1;
        composeShaders();
        glSys = new Present(GLSystem);
        program = glSys.createProgram(vertShader, fragShader);
    }

    public function start(outputBuffer:OutputBuffer):Void {
        activate();
        glSys.start(outputBuffer);
        glSys.clear(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundAlpha);
    }

    public function finish():Void {
        deactivate();
        glSys.finish();
    }

    function activate():Void glSys.setProgram(program);
    function deactivate():Void {}
    function composeShaders():Void {}
    function makeVertexShader():String return '';
    function makeFragmentShader():String return '';
}

