package net.rezmason.scourge.textview;

enum Command {
    EMPTY;
    ERROR(message:String);
    COMMIT(message:String);
    CHAT(message:String);
    LIST(filteredMoves:Array<String>);
}
