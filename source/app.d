import std.stdio;
import std.getopt;
import std.random;

import vindinium;

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

    Vindinium.Mode mode;
    switch(mode_str) with(Vindinium.Mode) {
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

    Vindinium c = Vindinium(key, server, mode, turns, map);
    auto game = c.connect();

    writeln("Started game in '%s' mode", mode);
    writeln("View the game at: ", game.view_url);

    while(!game.finished) {
        auto cmd = uniform!(VindiniumGame.Command);
        game.send_command(uniform!(VindiniumGame.Command));

        writefln("Turn %3d: Issued command: %s", game.turn, cmd);
    }
    writefln("Finished after %d total turns", game.turn);
    return 0;
}
