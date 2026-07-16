#+feature using-stmt
package main

import "core:math"
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

Particle :: struct {
    start : vec,
    pos   : vec,
    size  : vec,
    color : Palette,

    lifetime : f32,

    collision : bool,
    vel : vec,
    acc : vec,
}

particles : [1024 * 4] Particle

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
        rl.DrawTextureEx(tex, offset * window_size + pos * f32(SCALE), 0, tex_scale * size.x, 255)
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
                c := blocks[i * width + j] if blocks[i * width + j] != .NONE else .DARK_GRAY
                obj := &objs[n]

                obj.pos = { f32(j) + 0.5, f32(i) + 0.5 } 
                obj.acc.x = (rand.float32() - 0.5) / 10_000
                obj.acc.y = (rand.float32() - 0.1) / 10_000
                obj.col = c
                n += 1
            }
        }
        objs = objs[:n]
    }

    particles = {}
    
    rl.EndDrawing()
    for frame: int; frame < int(rl.GetFPS())*2; frame += 1 {
        if rl.WindowShouldClose() { should_quit = true; break }
        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground(colorscheme[.DARK_GRAY])

        render_wallpaper()

        for &obj, i in objs {
            draw_rectp(offsets.main, obj.pos - { 0.5, 0.5 }, vec{ 1, 1 }, obj.col)
            obj.pos += obj.vel      * 100 * rl.GetFrameTime()
            obj.vel += obj.acc      
            obj.acc *= 0.99 
            obj.acc.y += 0.000003   * 10 * rl.GetFrameTime()
        }
        should_quit = true
    }
    rl.BeginDrawing()
}

render_particles :: proc() {
    for &particle, i in particles {
        if particle.lifetime <= 0 { continue }
        draw_rectp(offsets.main, particle.pos, particle.size, particle.color)
        particle.lifetime -= 1

        particle.acc.y += 0.001
        particle.acc   *= 0.999
        particle.vel   *= 0.99

        particle.vel += particle.acc
        if particle.collision {
            curr_block := playfield.blocks[int(particle.pos.y) * playfield.width + int(particle.pos.x)]
            if curr_block != .NONE && curr_block != .DARK_GRAY && curr_block != particle.color {
                particle.vel = {}
            }
        }

        particle.pos += particle.vel
        if particle.collision {
            particle.pos.x = min(max(particle.pos.x,  1), 11)
            particle.pos.y = min(max(particle.pos.y,  1), 17)

        }
    }
}

add_particle :: proc(new_one: Particle) {
    new_one := new_one
    new_one.vel.x += (rand.float32() - 0.5) * 0.5
    for &particle, i in particles { if particle.lifetime <= 0 { particle = new_one; break } }
}

move_particle :: proc(p: Particle, delta: vec) -> Particle { p := p; p.pos += delta; return p }

block_break_effect :: proc(x, y: int, block: Palette) {
    if block == .NONE { return }
    base := Particle { pos = { f32(x), f32(y) }, size = 1.0 / 6, color = block, lifetime = 300, collision = true }

    add_particle(move_particle(base, { 0.25, 0.25 }))
    add_particle(move_particle(base, { 0.25, 0.75 }))
    add_particle(move_particle(base, { 0.75, 0.25 }))
    add_particle(move_particle(base, { 0.75, 0.75 }))
}
