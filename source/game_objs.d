module game_objs;

import stdx.data.json;
import std.conv;
import std.bitmanip;

struct Pos {
    uint x, y;

    static Pos from_json(JSONValue json) {
        auto pos = json.get!(JSONValue[string]);
        Pos ret;

        ret.x = pos["x"].get!double.to!uint;
        ret.y = pos["y"].get!double.to!uint;

        return ret;
    }
}

struct Hero {
    int id;
    string name;
    string user_id;
    uint elo;
    Pos pos;
    uint life;
    uint gold;
    uint mine_count;
    Pos spawn;
    bool crashed;

    static Hero from_json(JSONValue json) {
        auto hero = json.get!(JSONValue[string]);
        Hero ret;

        ret.id         = hero["id"].get!double.to!int;
        ret.name       = hero["name"].get!string;
        ret.pos        = Pos.from_json(hero["pos"]);
        ret.life       = hero["life"].get!double.to!uint;
        ret.gold       = hero["gold"].get!double.to!uint;
        ret.mine_count = hero["mineCount"].get!double.to!uint;
        ret.spawn      = Pos.from_json(hero["spawnPos"]);
        ret.crashed    = hero["crashed"].get!bool;

        // might not be in the JSON response, as they're training dummies
        if("elo" in hero)    ret.elo = hero["elo"].get!double.to!uint;
        if("userId" in hero) ret.user_id    = hero["userId"].get!string;

        return ret;
    }
}

struct Board {
    struct Tile {
        enum Type : ubyte {
            Empty,
            Wood,
            Hero,
            Tavern,
            Mine
        }

    private:
        mixin(bitfields!(
            // type of the item
            Type, "_type", 3,
            // is the tavern neutral?
            bool, "_neutral", 1,
            // hero ID
            uint, "_id", 4));

    public:
        Type type() { return _type; }
        bool neutral() {
            assert(type == Type.Mine);
            return _neutral;
        }

        uint id() {
            assert(type == Type.Hero || type == Type.Mine);
            return  _id;
        }

        this(Type type, uint id) {
            assert(type == Type.Hero || type == Type.Mine);
            this._type = type;
            this._id   = id;
            this._neutral = false;
        }

        this(Type type) {
            this._type = type;
            this._neutral = true;
        }
    }

    // board dimentions
    uint size;

    // [x][y]
    Tile[][] tiles;

    static Board from_json(JSONValue json) {
        Board ret;
        auto board = json.get!(JSONValue[string]);

        immutable size = board["size"].get!double.to!uint;
        auto tiles_str = board["tiles"].get!string;

        assert((size * size) == (tiles_str.length/2),
            "Size vs actual tile string length mismatch!");

        ret.size = size;
        ret.tiles = new Tile[][](size, size);

        uint idx = 0;
        foreach(y; 0..size) {
        foreach(x; 0..size) {
            Tile t;
            string tile = tiles_str[idx .. idx + 2];

            if(tile == "  ") {
                t = Tile(Tile.Type.Empty);
            }
            else if(tile == "##") {
                t = Tile(Tile.Type.Wood);
            }
            else if(tile[0] == '@') {
                t = Tile(Tile.Type.Hero, tile[1 .. 2].to!uint);
            }
            else if(tile == "[]") {
                t = Tile(Tile.Type.Tavern);
            }
            else if(tile[0] == '$') {
                if(tile[1] == '-') {
                    t = Tile(Tile.Type.Mine);
                }
                else {
                    t = Tile(Tile.Type.Mine, tile[1 .. 2].to!uint);
                }
            }
            else {
                assert(false, "Invalid tile on board: `" ~ tile ~ "`");
            }

            ret.tiles[x][y] = t;
            idx += 2;
        }
        }

        return ret;
    }
}

struct Game {
    string id;
    uint turn;
    uint max_turns;
    Hero[] heros;
    Board board;
    bool finished;

    static Game from_json(JSONValue json) {
        Game ret;
        auto game = json.get!(JSONValue[string]);

        ret.id          = game["id"].get!string;
        ret.turn        = game["turn"].get!double.to!uint;
        ret.max_turns   = game["maxTurns"].get!double.to!uint;

        foreach(hero_json; game["heroes"].get!(JSONValue[])) {
            ret.heros ~= Hero.from_json(hero_json);
        }

        ret.board    = Board.from_json(game["board"]);
        ret.finished = game["finished"].get!bool;

        return ret;
    }
}

struct GameResponse {
    Game game; /// initial game state
    Hero hero; /// the player's hero
    string token;
    string view_url;
    string play_url;

    static GameResponse from_json(JSONValue json) {
        GameResponse ret;

        auto gr = json.get!(JSONValue[string]);

        ret.game     = Game.from_json(gr["game"]);
        ret.hero     = Hero.from_json(gr["hero"]);
        ret.token    = gr["token"].get!string;
        ret.view_url = gr["viewUrl"].get!string;
        ret.play_url = gr["playUrl"].get!string;

        return ret;
    }
}
