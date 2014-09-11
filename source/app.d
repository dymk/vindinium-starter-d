import std.stdio;
import std.getopt;
import std.random;

import comms;

int main(string[] args) {
    string server  = "vindinium.org";
    string mode_str = "training";
    string key;
    string map = "m1";
    uint turns = 300;

    getopt(args,
        "server", &server,
        "mode", &mode_str,
        "key", &key,
        "turns", &turns,
        "map", &map);

    if(!server.length) {
        writeln("No server set");
        return -1;
    }

    if(!key.length) {
        writeln("No key set");
        return -1;
    }

    if(!map.length) {
        writeln("No map set");
        return -1;
    }

    if(turns < 10) {
        writeln("At least 10 turns required");
        return -1;
    }

    GameConnection.Mode mode;
    switch(mode_str) with(GameConnection.Mode) {
        case "training":
            mode = Training;
            break;

        case "arena":
            mode = Arena;
            break;

        default:
            writeln("Invalid mode, expected 'arena' or 'training'");
            return -1;
    }

    GameConnection c = GameConnection(key, server, mode, turns, map);
    c.connect();

    writeln("View the game at: ", c.view_url);

    while(c.is_running) {
        auto cmd = uniform!(GameConnection.Command);
        c.send_command(uniform!(GameConnection.Command));

        writefln("Turn %3d: Issued command: %s", c.game_response.game.turn, cmd);
    }
    writefln("Finished after %d total turns", c.game_response.game.turn);
    return 0;
}
