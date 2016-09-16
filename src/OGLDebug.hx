package;

import lime.app.Application;
import ogldebug.*;

class OGLDebug extends Application {

    var cubeTest:CubeTest;
    var floatRTTTest:FloatRTTTest;

    override public function onPreloadComplete() {
        super.onPreloadComplete();
        // cubeTest = new CubeTest(window.width, window.height);
        floatRTTTest = new FloatRTTTest(window.width, window.height);
    }

    override public function render(_) {
        // cubeTest.render();
        floatRTTTest.render();
    }
}
