package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.controller.players.*;

using Lambda;

typedef PlayerHandler = Player->GameEvent->Void;

class PlayerFactory {

    public static function makePlayers(playerConfigs:Array<PlayerConfig>, handler:PlayerHandler):Array<Player> {
        return playerConfigs.map(callback(makePlayer, handler)).array();
    }

    private inline static function makePlayer(handler:PlayerHandler, config:PlayerConfig):Player {
        switch (config.type) {
            case Test: return new TestPlayer(config, handler);
            case Human: return new HumanPlayer(config, handler);
            case Machine: return new MachinePlayer(config, handler);
            case Remote: return new RemotePlayer(config, handler);
        }
        return null;
    }
}
