package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.utils.Zig;

class NavSystem {

    var pages:Map<String, NavPage>;
    var currentPage:NavPage;
    var engine:Engine;

    public function new(engine:Engine):Void {
        pages = new Map();
        this.engine = engine;
    }

    public function addPage(name:String, page:NavPage):Void {
        pages[name] = page;
        if (page != null) page.navToSignal.add(goto);
    }

    public function removePage(name:String):Void {
        var page:NavPage = pages[name];
        if (page != null) page.navToSignal.remove(goto);
        pages.remove(name);
    }

    public function goto(address:NavAddress):Void {
        switch (address) {
            case Page(id):
                if (pages[id] != null) {
                    if (currentPage != null) for (body in currentPage.bodies) engine.removeBody(body);
                    currentPage = pages[id];
                    if (currentPage != null) for (body in currentPage.bodies) engine.addBody(body);
                }
            case Gone:
                #if (neko || cpp)
                    Sys.exit(0);
                #end
            case _:
        }
    }
}
