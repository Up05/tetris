package main

import rl "vendor:raylib"

playfield : struct {
    width, height : int,
    blocks : [] Palette,
}
clear_playfield :: proc() {
    using playfield
    for i in 0..<height {
        for j in 0..<width {
            blocks[i * width + j] = .NONE
        }
    }
}

enwall_playfield :: proc() {
    for _, j in 0..<playfield.width {
        playfield.blocks[j] = .GRAY
        playfield.blocks[(playfield.height - 1) * playfield.width + j] = .GRAY
    }

    for _, i in 1..<playfield.height {
        playfield.blocks[i * playfield.width] = .GRAY
        playfield.blocks[i * playfield.width + (playfield.width - 1)] = .GRAY
    }

}

handle_line_clear :: proc() -> bool {
    using playfield
    assert(width > 0)
    
    for y := height - 2; y >= 1; y -= 1 {
        should_line_clear := true
        for x in 0..<width {
            if blocks[y * width + x] == .NONE do should_line_clear = false
        }
        if should_line_clear {
            for i := y - 1; i >= 1; i -= 1 {
                for j in 0..<width {
                    blocks[(i + 1) * width + j] = blocks[i * width + j]
                }
            }
            handle_line_clear()
            break
        }
    }
    return true
}

handle_top_out :: proc() {
    using playfield
    topped_out = true
    render_top_out()
    
    clear_playfield()
    enwall_playfield()
}
