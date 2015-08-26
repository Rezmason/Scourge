package;

import lime.app.Application;

class ScourgeLab extends Application {
    override public function onPreloadComplete() {
        super.onPreloadComplete();
        #if flash flash.Lib.redirectTraces(); #end
        new net.rezmason.scourge.Lab(window.width, window.height);
    }
}
