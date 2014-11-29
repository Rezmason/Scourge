package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Scene;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.utils.Zig;

class NavSystem {

    var pages:Map<String, NavPage>;
    var pageHistory:Array<NavPage>;
    var currentPage:NavPage;
    var currentScenes:Array<Scene>;
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
                    pageHistory.push(currentPage);
                    currentPage = pages[id];
                    updateCurrentView();
                }
            case Gone:
                #if (neko || cpp)
                    Sys.exit(0);
                #end
            case Back:
                if (pageHistory.length > 0) {
                    currentPage = pageHistory.pop();
                    updateCurrentView();
                }
            case _:
        }
    }

    private function updateCurrentView():Void {
        if (currentScenes != null) for (scene in currentScenes) engine.removeScene(scene);
        if (currentPage != null) {
            currentScenes = currentPage.scenes.copy();
            for (scene in currentScenes) engine.addScene(scene);
        } else {
            currentScenes = null;
        }
    }
}
