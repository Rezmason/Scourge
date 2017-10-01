package net.rezmason.scourge.pages;

// import net.rezmason.hypertype.console.*;
// import net.rezmason.hypertype.core.Container;
// import net.rezmason.hypertype.core.Stage;
// import net.rezmason.hypertype.demo.*;
import net.rezmason.hypertype.nav.NavPage;
// import net.rezmason.hypertype.useractions.*;
// import net.rezmason.scourge.View;
// import net.rezmason.scourge.useractions.PlayGameAction;
// import net.rezmason.scourge.waves.WaveDemo;
import net.rezmason.utils.santa.Present;

class GamePage extends NavPage {

    public function new():Void {
        super();
        var view:View = new Present(View);
        container.boundingBox.scaleMode = SHOW_ALL;
        container.addChild(view.container);
    }
}
