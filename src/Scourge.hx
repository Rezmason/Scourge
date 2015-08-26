package;

import lime.app.Application;

class Scourge extends Application {
    override public function onPreloadComplete() {
        super.onPreloadComplete();
        #if flash flash.Lib.redirectTraces(); #end
        trace('\n${lime.Assets.getText('text/splash.txt')}');
        new net.rezmason.scourge.Context();
    }
}
