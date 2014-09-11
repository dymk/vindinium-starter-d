module comms;

import game_objs;

private {
    import std.net.curl;
    import std.string;
    import std.stdio;
    import std.exception;
    import stdx.data.json;
}

/**
 * Server communications module
 */

enum Flags {
    Get = 0x1,
    Set = 0x2,
    Both = 0x3
}
mixin template Property(Type, string name, Flags flags) {
    mixin("private " ~ Type.stringof ~ " _" ~ name ~ ";");

    static if(flags & Flags.Get) {
        mixin(Type.stringof ~ " " ~ name ~ "() const @property @safe @nogc nothrow { return _" ~ name ~ "; }");
    }
    static if(flags & Flags.Set) {
        mixin("void " ~ name ~ "(" ~ Type.stringof ~ " _setarg) @property @safe @nogc nothrow { _" ~ name ~ " = _setarg; }");
    }
}

struct GameConnection {
    /// Game modes
    enum Mode {
        Training,
        Arena
    }

    /// Commands that the hero can be issued
    enum Command {
        Stay,
        North,
        South,
        East,
        West
    }

    const {
        /// The AI's private API key
        string key;

        /// Server to play the game on
        string server;

        /// Mode that the hero is playing in
        Mode mode;

        /// Number of turns to play the game
        uint turns;

        /// Name of the map to play: "m{1..6}"
        string map;
    }


    // URL to view the game over
    mixin Property!(string, "view_url", Flags.Get);

    private bool _is_connected = false;
    private HTTP _conn;
    private GameResponse _gr;

    bool is_running() {
        return _is_connected && !_gr.game.finished;
    }

    // Delegated to the game response
    string play_url() @property @safe { return _gr.play_url; }
    string view_url() @property @safe { return _gr.view_url; }
    const(GameResponse) game_response() { return _gr; }

    void connect()
    in { assert(!_is_connected); }
    out { assert(_is_connected); }
    body {
        _conn = HTTP();

        string uri;
        final switch(mode)
        with(Mode) {
            case Training:
                uri = server ~ "/api/training";
                break;

            case Arena:
                uri = server ~ "/api/arena";
                assert(false, "Not implemented yet");
                //break;
        }

        _conn.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        _conn.setUserAgent("Vindinium-D-Client/0.0.1");

        string post_data = format("key=%s&turns=%s&map=%s", key, turns, map);
        writeln("Posting data to server: ", post_data);
        string response = post(uri, post_data, _conn).assumeUnique;

        parse_response(response);

        _is_connected = true;
    }

    private void parse_response(string resp) {
        auto json = parseJSONValue(resp);
        _gr = GameResponse.from_json(json);
    }

    void send_command(Command cmd)
    in { assert(is_running); }
    body {
        string cmd_str;
        final switch(cmd)
        with(Command) {
            case Stay: cmd_str = "Stay"; break;
            case North: cmd_str = "North"; break;
            case South: cmd_str = "South"; break;
            case East: cmd_str = "East"; break;
            case West: cmd_str = "West"; break;
        }

        auto post_data = format("key=%s&dir=%s", key, cmd_str);
        string response = post(play_url, post_data, _conn).assumeUnique;

        // TODO: merge changes instead of overwriting the game response
        parse_response(response);
    }

    ~this() {
        _conn.shutdown();
    }
}
