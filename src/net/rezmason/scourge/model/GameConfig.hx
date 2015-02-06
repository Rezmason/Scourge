package net.rezmason.scourge.model;

class GameConfig {
    
    public var params(default, null):Map<String, Dynamic> = new Map();
    public var configs(default, null):Map<String, Config<Dynamic>> = new Map();

    public function new(defs:Map<String, Class<Config<Dynamic>>>) {
        for (key in defs.keys()) {
            configs[key] = Type.createInstance(defs[key], []);
            params[key] = configs[key].defaultParams();
        }
    }
}
