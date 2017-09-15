package net.rezmason.hypertype.nav;

import net.rezmason.hypertype.core.Container;

class NavSystem {

    public var container(default, null):Container;
    var pages:Map<String, NavPage>;
    var pageHistory:Array<NavPage>;
    var currentPage:NavPage;

    public function new():Void {
        container = new Container();
        container.boundingBox.width  = Proportion(1);
        container.boundingBox.height = Proportion(1);
        pages = new Map();
        pageHistory = [];
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
        if (currentPage != null) container.removeChild(currentPage.container);
        currentPage = page;
        if (currentPage != null) container.addChild(currentPage.container);
    }
}
