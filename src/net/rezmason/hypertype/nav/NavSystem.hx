package net.rezmason.hypertype.nav;

import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.utils.santa.Present;

class NavSystem {

    var sceneGraph:SceneGraph;
    var pages:Map<String, NavPage>;
    var pageHistory:Array<NavPage>;
    var currentPage:NavPage;

    public function new():Void {
        sceneGraph = new Present(SceneGraph);
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
        if (currentPage != null) sceneGraph.scene.root.removeChild(currentPage.body);
        currentPage = page;
        if (currentPage != null) sceneGraph.scene.root.addChild(currentPage.body);
    }
}
