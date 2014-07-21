package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.utils.Zig;

class NavSystem {

    var pages:Map<String, NavPage>;
    var currentPage:NavPage;
    var currentBodies:Array<Body>;
    var engine:Engine;

    public function new(engine:Engine):Void {
        pages = new Map();
        this.engine = engine;
    }

    public function addPage(name:String, page:NavPage):Void {
        pages[name] = page;
        if (page != null) {
            page.navToSignal.add(goto);
            page.updateViewSignal.add(updateCurrentView);
        }
    }

    public function removePage(name:String):Void {
        var page:NavPage = pages[name];
        if (page != null) {
            page.navToSignal.remove(goto);
            page.updateViewSignal.remove(updateCurrentView);

            if (currentPage == page) {
                currentPage = null;
                updateCurrentView();
            }
        }
        pages.remove(name);
    }

    public function goto(address:NavAddress):Void {
        switch (address) {
            case Page(id):
                if (pages[id] != null) {
                    currentPage = pages[id];
                    updateCurrentView();
                }
            case Gone:
                #if (neko || cpp)
                    Sys.exit(0);
                #end
            case _:
        }
    }

    private function updateCurrentView():Void {
        if (currentBodies != null) for (body in currentBodies) engine.removeBody(body);
        if (currentPage != null) {
            currentBodies = currentPage.bodies.copy();
            for (body in currentBodies) engine.addBody(body);
        } else {
            currentBodies = null;
        }
    }
}
