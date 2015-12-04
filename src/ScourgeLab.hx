package;

import lime.app.Application;
import net.rezmason.scourge.Lab;

class ScourgeLab extends Application {

    var lab:Lab;

    override public function onPreloadComplete() {
        super.onPreloadComplete();
        #if flash flash.Lib.redirectTraces(); #end
        lab = new Lab(window.width, window.height);
    }

    override public function render(_) lab.render();
}
