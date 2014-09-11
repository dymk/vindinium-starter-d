vindinium-starter-d
====

A Vindinium starter written in the D language. The starter sends random
movement commands to the server. Go implement your own AI!

This project implements a simple driver around https://github.com/dymk/vindinium-client,
which you should look at if you want to implement your own driver, and to learn
about how to use the client library.

The driver accepts the command line parameters:
```
  --key=<your secret key>
  --turns=<number of turns> | 300
  --mode=training|arena
```
