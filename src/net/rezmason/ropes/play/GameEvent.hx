package net.rezmason.ropes.play;

enum GameEvent {
    SubmitMove(turn:Int, action:String, move:Int);
    Init(config:String, ?savedState:String);
    RelayMove(turn:Int, action:String, move:Int);
    RandomFloats(turn:Int, floats:String);
    Time(mils:Int);
    End;
}
