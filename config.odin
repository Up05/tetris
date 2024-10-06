package main

import "core:os"
import "core:strings"
import "core:strconv"
import "core:reflect"
import rl "vendor:raylib"
// import "ini"
import "core:encoding/ini"
import "base:runtime"

Palette :: enum u8 {
    NONE,
    AQUA, YELLOW,
    PURPLE,
    BLUE, ORANGE,
    GREEN, RED,
    DARK_GRAY, GRAY // I am sorry to all the British people...
}

colorscheme : [Palette] col

tps : f32

@(private="file")
config: ini.Map

setup :: proc() {
    res: runtime.Allocator_Error
    ok: bool
    
    // later ~/.config/ulti/tetris/config.ini
    config, res, ok = ini.load_map_from_path("config.ini", context.allocator, ini.Options { "#", true })
    if res != nil || !ok {
        config, res = ini.load_map_from_string(#load("/home/ulti/.config/ulti/tetris/config.ini", string), context.allocator, ini.Options { "#", true })
        if res != nil {
            logf("Bro, get more memory.... What the fuck?")
            os.exit(1)
        }
    }

    tps = strconv.parse_f32(config["game"]["tps"]) or_else 3

    playfield.width  = strconv.parse_int(config["playfield"]["col"]) or_else 10
    playfield.height = strconv.parse_int(config["playfield"]["row"]) or_else 16
    playfield.width  += 2
    playfield.height += 2
    playfield.blocks = make([] Palette, playfield.width * playfield.height)
    
    for a in Action {
        keystr := config["keys"][strings.to_lower(reflect.enum_string(a))]
        keys := strings.split(keystr, ",")
        actions[a] = make([] rl.KeyboardKey, len(keys))
        for key_name, i in keys {
            key_name := strings.trim_left_space(key_name)
            rlkey, ok := reflect.enum_from_name(rl.KeyboardKey, key_name)
            assertf(ok, "[CONFIG ERROR] Found an unknown key: '%s' in config.ini! Try checking keylist.txt", key_name)
            actions[a][i] = rlkey
        } 

    }

    window_size.x = strconv.parse_f32(config["window"]["width"])  or_else 640
    window_size.y = strconv.parse_f32(config["window"]["height"]) or_else 720
    SCALE = strconv.parse_int(config["window"]["scale"]) or_else 32
}

load_images :: proc() {

    for e in Palette {
        colorscheme[e] = parse_hex_color(config["colorscheme"][strings.to_lower(reflect.enum_string(e))])
    }
    images.use_images    = strings.starts_with(config["images"]["use_images"], "true")
    images.use_wallpaper = strings.starts_with(config["images"]["use_wallpaper"], "true")
    wallpaper_path := strings.concatenate({ config_path, config["images"]["wallpaper"] })
    images.wallpaper     = rl.LoadTexture( strings.clone_to_cstring(wallpaper_path))
    images.use_wallpaper &&= rl.IsTextureReady(images.wallpaper)
    for color in Palette {
        img_path := strings.concatenate({ config_path, config["images"][strings.to_lower(reflect.enum_string(color))] })
        images.palette[color] = rl.LoadTexture( strings.clone_to_cstring(img_path))
        images.use_images &&= rl.IsTextureReady(images.palette[color])
    }

}

parse_hex_color :: proc(color: string) -> col {
    res: col
    res.r = parse_hex(color[0]) * 16 + parse_hex(color[1])
    res.g = parse_hex(color[2]) * 16 + parse_hex(color[3])
    res.b = parse_hex(color[4]) * 16 + parse_hex(color[5])
    res.a = parse_hex(color[6]) * 16 + parse_hex(color[7])

    return res
}

parse_hex :: proc(r: u8) -> u8 {
    if r < '0' do return 0
    if r >= '0' && r <= '9' do return r - '0' // kind of inefficient, but I might be misremembering the ascii table
    if r >= 'A' && r <= 'F' do return r - 'A' + 10
    if r >= 'a' && r <= 'f' do return r - 'a' + 10
    return 0
}

