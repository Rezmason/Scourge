package;

import lime.app.Application;

class Scourge extends Application {
    override public function exec() {
        #if flash flash.Lib.redirectTraces(); #end
        trace('\n${lime.Assets.getText('text/splash.txt')}');
        new net.rezmason.scourge.Context();
        return super.exec();
    }
}
