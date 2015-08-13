package net.rezmason.scourge.textview.useractions;

// import massive.munit.TestRunner;

import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes;

class RunTestsAction extends UserAction {

    public function new():Void {
        super();
        name = 'runTests';
    }

    override public function execute(args:UserActionArgs):Void {
        /*
        var client = new SimpleTestClient();
        var runner:TestRunner = new TestRunner(client);
        runner.completionHandler = function(b) {};
        runner.run([TestSuite]);
        outputSignal.dispatch(client.output, true);
        */
        outputSignal.dispatch('NOPE', true);
    }
}
