package net.rezmason.scourge.errands;

import net.rezmason.hypertype.nav.NavSystem;
import net.rezmason.scourge.pages.*;
import net.rezmason.utils.Errand;
import net.rezmason.utils.santa.Present;

class BeginNavErrand extends Errand<Void->Void> {

    public function new() {}

    override public function run():Void {
        var navSystem = new NavSystem();
        navSystem.addPage(ScourgeNavPageAddresses.SPLASH, new SplashPage());
        navSystem.addPage(ScourgeNavPageAddresses.ABOUT, new AboutPage());
        navSystem.addPage(ScourgeNavPageAddresses.GAME, new GamePage());
        navSystem.goto(Page(ScourgeNavPageAddresses.SPLASH));
        onComplete.dispatch();
    }
}
