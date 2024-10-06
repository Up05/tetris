# tetris
Quite customizable tetris clone for linux

I couldn't find any good tetris clones for Linux. Weird... So I made my own over the breaks in college.

![image](https://github.com/user-attachments/assets/4b28c39c-bba5-40e0-85d0-2dc865b7162f)

# Installation

If you're on Linux: just grab a release from github and `link tetris /usr/local/bin/tetris` or smth
Otherwise, you'll need to build the project yourself... I might build it on windows, if I will ever not be too lazy to do so.

## Building

You will need [odin](https://github.com/odin-lang/Odin)
Afterwards:
```sh
git clone https://github.com/Up05/tetris 
cd tetris
compile.sh
```
or (if you're on Windows)
```
odin build .
```

# Configuration

Config files and assets should be located at `~/.config/ulti/tetris/` or `%HOME%/.config/...`
You can edit the assets as you please. Scaling the textures up or down should not have any bad effect, although, I have not tested that yet.

If any texture (except wallpaper) cannot be loaded, the game will use gruvbox theme colors.
If config.ini cannot be loaded, the game will use the config that was loaded at build time.
So you can just not have anything in `~/.config/ulti` and the game should still run.

Default colorscheme is gruvbox, you can change that just by changing the values in config.ini and texture colors.


