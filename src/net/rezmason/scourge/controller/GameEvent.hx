package net.rezmason.scourge.controller;

enum GameEvent {
    SubmitMove(turn:Int, action:Int, move:Int);
    Init(config:String, ?savedState:String);
    RelayMove(turn:Int, action:Int, move:Int);
    RandomFloats(turn:Int, floats:String);
    Time(mils:Int);
    End;
}
