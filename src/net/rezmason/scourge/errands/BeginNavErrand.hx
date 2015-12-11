package net.rezmason.scourge.errands;

import net.rezmason.scourge.pages.*;
import net.rezmason.hypertype.core.Engine;
import net.rezmason.hypertype.nav.NavSystem;
import net.rezmason.utils.Errand;

class BeginNavErrand extends Errand<Void->Void> {

    var engine:Engine;

    public function new(engine:Engine):Void this.engine = engine;

    override public function run():Void {

        engine.readySignal.remove(run);

        var navSystem = new NavSystem();

        navSystem.addSceneSignal.add(engine.addScene);
        navSystem.removeSceneSignal.add(engine.removeScene);

        navSystem.addPage(ScourgeNavPageAddresses.SPLASH, new SplashPage());
        navSystem.addPage(ScourgeNavPageAddresses.ABOUT, new AboutPage());
        navSystem.addPage(ScourgeNavPageAddresses.GAME, new GamePage());
        navSystem.goto(Page(ScourgeNavPageAddresses.SPLASH));
        
        onComplete.dispatch();
    }
}
