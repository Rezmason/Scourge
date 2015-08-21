package;

import lime.app.Application;

class ScourgeLab extends Application {
    override public function exec() {
        #if flash flash.Lib.redirectTraces(); #end
        new net.rezmason.scourge.Lab(window.width, window.height);
        return super.exec();
    }
}
