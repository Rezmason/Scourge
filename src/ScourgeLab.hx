package;

import lime.app.Application;

class ScourgeLab extends Application {
    
    override public function exec() {
        #if flash flash.Lib.redirectTraces(); #end
        new net.rezmason.scourge.Lab(window.width, window.height);
        return super.exec();
    }

    public override function onRenderContextLost():Void {
        super.onRenderContextLost();
    }

    public override function onRenderContextRestored(_):Void {
        super.onRenderContextRestored(_);
    }
}
