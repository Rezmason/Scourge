package net.rezmason.ash.tick;

import nme.Lib;
import nme.events.IEventDispatcher;
import nme.events.Event;

import ash.signals.Signal1;
import ash.tick.ITickProvider;

class EventTickProvider implements ITickProvider {
    private var dispatcher:IEventDispatcher;
    private var eventType:String;
    private var previousTime:Float;
    private var maximumFrameTime:Float;
    private var signal:Signal1<Float>;

    public var timeAdjustment:Float = 1;

    public function new(dispatcher:IEventDispatcher, eventType:String, maximumFrameTime:Float = 9999999999999999) {
        signal = new Signal1<Float>();
        this.dispatcher = dispatcher;
        this.eventType = eventType;
        this.maximumFrameTime = maximumFrameTime;
    }

    public function add(listener:Float->Void):Void {
        signal.add(listener);
    }

    public function remove(listener:Float->Void):Void {
        signal.remove(listener);
    }

    public function start():Void {
        previousTime = Lib.getTimer();
        dispatcher.addEventListener(eventType, dispatchTick);
    }

    public function stop():Void {
        dispatcher.removeEventListener(eventType, dispatchTick);
    }

    private function dispatchTick(event:Event):Void {
        var temp:Float = previousTime;
        previousTime = Lib.getTimer();
        var frameTime:Float = ( previousTime - temp ) / 1000;
        if (frameTime > maximumFrameTime)
            frameTime = maximumFrameTime;
        signal.dispatch(frameTime * timeAdjustment);
    }
}
