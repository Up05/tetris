package main

import "core:math/rand"
import rl "vendor:raylib"

window_size : vec
SCALE : int // 1 -- px

images : struct {
    use_images: bool,
    palette: [Palette] rl.Texture2D,
    use_wallpaper: bool,
    wallpaper: rl.Texture2D, 
} 

frame_count := 0 
offsets : struct {
    main : vec, // for playfield & pieces
    next : vec, // upcomming piece
}

calc_offsets :: proc() {
    half_playfield := vec { f32(playfield.width*SCALE), f32(playfield.height*SCALE) } / window_size / 2

    offsets.main = { .5, .5 } - half_playfield
    offsets.next = { .55, offsets.main.y } + { half_playfield.x, 0 }
}

draw_rectc :: proc(offset, pos, size: vec, color: col) {
    rl.DrawRectangleV(offset * window_size + pos*f32(SCALE), size*f32(SCALE), color)
}

draw_rectp :: proc(offset, pos, size: vec, color: Palette) {
    if images.use_images {
        tex := images.palette[color]
        tex_scale := f32(SCALE) / f32(tex.width)
        rl.DrawTextureEx(tex, offset * window_size + pos * f32(SCALE), 0, tex_scale, 255)
    } else {
        rl.DrawRectangleV(offset * window_size + pos*f32(SCALE), size*f32(SCALE), colorscheme[color])
    }
}

render_wallpaper :: proc() {
    if images.use_wallpaper {
        size := vec{ f32(images.wallpaper.width), f32(images.wallpaper.height) } * f32(SCALE)
        rl.DrawTextureEx(images.wallpaper, window_size / 2 - size / 2, 0, f32(SCALE), 255)
    }
}

render_playfield :: proc() {
    using playfield
    
    render_wallpaper()

    for i in 0..<height {
        for j in 0..<width {
            c := playfield.blocks[i * width + j]
            if c == .NONE {
                draw_rectp(offsets.main, { f32(j), f32(i) }, { 0.95, 0.95 }, .DARK_GRAY)
            } else {
                draw_rectp(offsets.main, { f32(j), f32(i) }, { 0.95, 0.95 }, c)
            } 
    
        }
    }
}

render_piece :: proc(delta: f32) {
    using curr_piece

    for i in 0..<4 {
        for j in 0..<4 {
            draw_rectp(offsets.main, { f32(pos.x + j), f32(pos.y + i) - 1 + delta }, { 1, 1 }, base.data[i][j])
        }
    }
}

render_next :: proc() {
    for i in 0..<4 {
        for j in 0..<4 {
            draw_rectp(offsets.next, { f32(j), f32(i) }, { 1, 1 }, base_pieces[next_piece_type].data[i][j])
        }
    }
}

render_top_out :: proc() {
    using playfield
    Obj :: struct {
        pos, vel, acc: vec,
        col: Palette
    }

    EXPLOSION_ORIGIN := vec { f32(width / 2) + 0.5, f32(height) }

    objs : #soa [] Obj = make(#soa [] Obj, width*height) 
    { 
        n := 0
        for i in 0..<height {
            for j in 0..<width {
                c := blocks[i * width + j]
                obj := &objs[n]
                if c != .NONE {
                    obj.pos = { f32(j) + 0.5, f32(i) + 0.5 } 
                    obj.acc.x = -0.0001 + 0.000002 * f32(i)
                    obj.acc.y = f32(i32(rand.float32() * 100) % 100) / -200000
                    obj.col = c
                    n += 1
                }
            }
        }
        objs = objs[:n]
    }
    
    rl.EndDrawing()
    for frame in 0..<int(rl.GetFPS())*4 {
        if rl.WindowShouldClose() do break
        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground(colorscheme[.DARK_GRAY])

        render_wallpaper()

        for &obj, i in objs {
            draw_rectp(offsets.main, obj.pos - { 0.5, 0.5 }, vec{ 1, 1 }, obj.col)
            obj.pos += obj.vel
            obj.vel += obj.acc
            obj.acc *= 0.99
            obj.acc.y += 0.000003
        }
    }
    rl.BeginDrawing()
}

