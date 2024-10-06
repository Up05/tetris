package main

import "core:fmt"
import "core:time"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

log   :: fmt.print
logf  :: fmt.printf
logln :: fmt.println

assertf :: fmt.assertf

col :: rl.Color
vec :: [2] f32

tick_count : int
topped_out : bool

config_path : string

main :: proc() {
 
    load_piece_scheme()
    setup()
    enwall_playfield()

    config_path := strings.concatenate({ os.get_env("HOME"), "/.config/ulti/tetris" })
    os.set_current_directory(config_path)

    rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_RESIZABLE }) // FULLSCREEN_MODE
    rl.InitWindow(i32(window_size.x), i32(window_size.y), "Tetris")
    load_images()

    rl.SetTargetFPS(60)

    handle_lockdown()

    TICK_FREQ := 1.0 / tps
    accumulator: f32
    prev_time := time.tick_now()

    for !rl.WindowShouldClose() {
        frame_duration := f32(time.duration_seconds(time.tick_since(prev_time)))
        prev_time = time.tick_now()
        accumulator += frame_duration
        ticks_to_do := int(accumulator / TICK_FREQ)
        accumulator -= f32(ticks_to_do) * TICK_FREQ

        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground(colorscheme[.DARK_GRAY])

        window_size.x = auto_cast rl.GetScreenWidth()
        window_size.y = auto_cast rl.GetScreenHeight()
        calc_offsets()

        handle_key_press()
        
        if topped_out { // skips the animation ticks
            topped_out = false
            continue
        }

        for tick in 0..<ticks_to_do {
            simulate()
            tick_count += 1
        }
        delta := accumulator / TICK_FREQ
        render(delta)
    }

}

render :: proc(delta: f32) {
    render_playfield()
    render_piece(delta)
    render_next()
    frame_count += 1
}

simulate :: proc() {
    if handle_delayed_funcs() do return
    update_piece()
    handle_line_clear()
}



