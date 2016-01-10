package net.rezmason.hypertype.core;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.GLSystem;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.Texture;
import net.rezmason.hypertype.core.RenderMethod;
import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.hypertype.core.SceneRenderMethod;
import net.rezmason.hypertype.core.ScreenRenderMethod;
import net.rezmason.utils.santa.Present;

class RenderPass {
    var steps:Array<RenderStep> = [];
    var glSys:GLSystem;
    public function new() glSys = new Present(GLSystem);
    public function addStep(step) steps.push(step);
    
    public function run() {
        if (!glSys.connected) return;
        for (step in steps) {
            switch (step) {
                case SceneStep(method, sceneGraph, renderTarget, args):
                    method.start(renderTarget, args);
                    for (scene in sceneGraph.eachScene()) method.drawScene(scene);
                    method.end();
                case ScreenStep(method, inputTextures, renderTarget, args):
                    method.start(renderTarget, args);
                    method.drawScreen(inputTextures);
                    method.end();
            }
        }
    }
}

enum RenderStep {
    SceneStep(method:SceneRenderMethod, sceneGraph:SceneGraph, renderTarget:RenderTarget, ?args:Array<Dynamic>);
    ScreenStep(method:ScreenRenderMethod, inputTextures:Map<String, Texture>, renderTarget:RenderTarget, ?args:Array<Dynamic>);
}
