package net.rezmason.scourge.textview.errands;

import net.rezmason.utils.Errand;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.pages.*;

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
