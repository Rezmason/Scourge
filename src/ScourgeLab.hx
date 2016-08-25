package;

import lime.app.Application;
import net.rezmason.scourge.lab.*;

class ScourgeLab extends Application {

    var labs:Array<Lab> = [];

    override public function onPreloadComplete() {
        super.onPreloadComplete();
        var width = window.width;
        var height = window.height;

        labs.push(new HalfFloatLab(width, height));
        labs.push(new RTTLab(width, height));
        labs.push(new CubeLab(width, height));
        labs.push(new MetaballSlimeLab(width, height));
    }

    override public function render(_) labs[0].render();

    override public function onMouseDown(_, _, _, button) {
        if (button == 0) labs.push(labs.shift());
        else labs.unshift(labs.pop());
        labs[0].render();
    }
}
