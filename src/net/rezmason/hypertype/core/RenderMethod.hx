package net.rezmason.hypertype.core;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.RenderTarget;
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
    var extensions:Array<String>;

    function new():Void {
        glSys = new Present(GLSystem);
        backgroundColor = new Vec3(0, 0, 0);
        backgroundAlpha = 1;
        extensions = [];
        composeShaders();
        var extensionPreamble = '\n';
        for (extension in extensions) {
            glSys.enableExtension(extension);
            extensionPreamble += '#extension GL_$extension : enable\n';
        }
        #if !desktop extensionPreamble += 'precision mediump float;\n'; #end
        program = glSys.createProgram(vertShader, extensionPreamble + fragShader);
    }

    public function start(renderTarget:RenderTarget, args:Array<Dynamic>):Void {
        glSys.setProgram(program);
        glSys.start(renderTarget);
        glSys.clear(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundAlpha);
    }

    public function end():Void glSys.end();
    function composeShaders():Void {}
    function makeVertexShader():String return '';
    function makeFragmentShader():String return '';
}

