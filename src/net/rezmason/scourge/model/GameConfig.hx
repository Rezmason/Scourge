package net.rezmason.scourge.model;

class GameConfig {
    
    public var params(default, null):Map<String, Dynamic> = new Map();
    public var configs(default, null):Map<String, Config<Dynamic>> = new Map();

    public function new(defs:Array<Class<Config<Dynamic>>>) {
        for (def in defs) {
            var config:Config<Dynamic> = Type.createInstance(def, []);
            configs[config.id()] = config;
            params[config.id()] = config.defaultParams();
        }
    }
}
