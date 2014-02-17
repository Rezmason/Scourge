package net.rezmason.scourge.textview.commands;

import massive.munit.TestRunner;

import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;

class RunTestsConsoleCommand extends ConsoleCommand {

    public function new():Void {
        super();
        name = 'runTests';
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        var client = new SimpleTestClient();
        var runner:TestRunner = new TestRunner(client);
        runner.completionHandler = function(b) {};
        runner.run([TestSuite]);
        outputSignal.dispatch(client.output, true);
    }
}
