package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Scene;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.utils.Zig;

class NavSystem {

    var pages:Map<String, NavPage>;
    var pageHistory:Array<NavPage>;
    var currentPage:NavPage;
    var engine:Engine;

    public function new(engine:Engine):Void {
        pages = new Map();
        pageHistory = [];
        this.engine = engine;
    }

    public function addPage(name:String, page:NavPage):Void {
        pages[name] = page;
        if (page != null) {
            page.navToSignal.add(goto);
        }
    }

    public function removePage(name:String):Void {
        var page:NavPage = pages[name];
        if (page != null) {
            page.navToSignal.remove(goto);
            if (currentPage == page) setPageTo(null);
        }
        pages.remove(name);
    }

    public function goto(address:NavAddress):Void {
        switch (address) {
            case Page(id):
                if (pages[id] != null) {
                    pageHistory.push(currentPage);
                    setPageTo(pages[id]);
                }
            case Gone:
                #if (neko || cpp)
                    Sys.exit(0);
                #end
            case Back:
                if (pageHistory.length > 0) setPageTo(pageHistory.pop());
            case _:
        }
    }

    private function setPageTo(page:NavPage):Void {
        if (currentPage != null) for (scene in currentPage.eachScene()) engine.removeScene(scene);
        currentPage = page;
        if (currentPage != null) for (scene in currentPage.eachScene()) engine.addScene(scene);
    }
}
