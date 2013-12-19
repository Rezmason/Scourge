package net.rezmason.utils;

class TempWorker<T, U> extends BasicWorker<T, U> {

    var process:T->U;

    public function new(process:T->U):Void {
        this.process = process;
        super();
    }

    override function receive(data:T):Void {
        try {
            send(process(data));
        } catch (error:Dynamic) {
            sendError(error);
        }
    }
}
