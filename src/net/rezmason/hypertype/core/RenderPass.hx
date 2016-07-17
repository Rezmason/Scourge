package net.rezmason.hypertype.core;

import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.Texture;
import net.rezmason.hypertype.core.RenderMethod;
import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.hypertype.core.SceneRenderMethod;
import net.rezmason.hypertype.core.ScreenRenderMethod;

class RenderPass {
    var steps:Array<RenderStep> = [];
    public function new() {}
    public function addStep(step) steps.push(step);
    
    public function run() {
        for (step in steps) {
            switch (step) {
                case SceneStep(method, sceneGraph, renderTarget, args):
                    method.start(renderTarget, args);
                    method.drawScene(sceneGraph.scene);
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
