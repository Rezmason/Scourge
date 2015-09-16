package net.rezmason.praxis.bot;

import net.rezmason.praxis.play.GameEvent;

class RandomSmarts extends Smarts {

    override public function choose():GameEvent {
        var type:GameEvent = null;
        var rev:Int = game.revision;

        var ids = [];
        var numMoves:Map<String, Int> = new Map();
        for (id in game.actionIDs) {
            if (id == 'forfeit') continue;
            var num = game.getMovesForAction(id).length;
            if (num > 0) {
                ids.push(id);
                numMoves[id] = num;
            }
        }

        if (ids.length > 0) {
            var id = ids[randIntRange(ids.length)];
            type = SubmitMove(game.revision, id, randIntRange(numMoves[id]));
        } else {
            type = SubmitMove(game.revision, 'forfeit', 0);
        }

        return type;
    }
}
