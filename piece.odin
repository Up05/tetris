package main

import "core:math"
import "core:math/rand"
import "core:math/linalg"
import rl "vendor:raylib"

PieceType :: enum u8 {
    I, O, 
    T, 
    J, L, 
    S, Z,
}
Piece :: struct {
    data: [4][4] Palette,
    width, height: int
}

base_pieces : [PieceType] Piece
curr_piece  : struct {
    base : Piece,
    type : PieceType,
    pos  : [2] int,
}

next_piece_type : PieceType

load_piece_scheme :: proc() {//{{{
    raw   := #load("pieces", string)
    piece : ^Piece
    x, y  : int
    color : Palette

    skip : bool
    for r, i in raw {
        if skip {
            skip = false
            continue
        }
        switch r {
        case '\x00': return
        case ' ':
            x += 1 
        case '#':
            piece.data[y][x] = color
            x += 1
            piece.width = max(piece.width, x)
        case '\n': // You shouldn't use OS 9 anyways
            x  = 0
            y += 1
            piece.height = y
        case '0'..<'z':
            piece = &base_pieces[PieceType(r - '1')]
            color = Palette(r - '0')
            x, y = 0, 0
            skip = true
        }
    }
}//}}}

should_lockdown :: proc() -> bool {
    using curr_piece

    for i in 0..<4 {
        for j in 0..<4 {
            if base.data[i][j] != .NONE && playfield.blocks[(pos.y + i) * playfield.width + pos.x + j] != .NONE {
                return true
            }
        }
    }
    
    return false
}

handle_lockdown :: proc() {
    using curr_piece

    // log_accumulated_states()
    
    for i in 0..<4 {
        for j in 0..<4 {
            if base.data[i][j] != .NONE {
                playfield.blocks[(pos.y + i) * playfield.width + pos.x + j] = base.data[i][j]
            }
        }
    }
    type = next_piece_type if tick_count > 1 else rand.choice_enum(PieceType)
    next_piece_type = rand.choice_enum(PieceType)
    base = base_pieces[type]
    pos  = { playfield.width / 2 - 2, 1 }

    if should_lockdown() {
        handle_top_out()
    }
}

calc_size :: proc(data: [4][4] Palette) -> (size: [2] int) {
    for row, i in data {
        ones  : [4] i8 = transmute([4] i8) { row.x != .NONE, row.y != .NONE, row.z != .NONE, row.w != .NONE }
        size.x = auto_cast max(ones.x, ones.y*2, ones.z*3, ones.w*4, i8(size.x))
        if size.x != 0 do size.y = i
    }
    return
}

move :: proc(left: bool) {
    using curr_piece

    dir := -1 if left else 1
    pos.x += dir
    if should_lockdown() do pos.x -= dir
}

rotate :: proc(right: bool) {
    using curr_piece

    swap2 :: proc(i1, j1, i2, j2: int) {
        base.data[i1][j1], base.data[i2][j2] = base.data[i2][j2], base.data[i1][j1]
    }

    if type == .I {
        if !right do transpose_4x4(&base.data)
        swap2(1, 0,  2, 0)
        swap2(1, 1,  2, 1)
        swap2(1, 2,  2, 2)
        swap2(1, 3,  2, 3)
        if right do transpose_4x4(&base.data)
    } else if type != .O {
        if right do transpose_4x4(&base.data)
        swap2(0, 0,  0, 2)
        swap2(1, 0,  1, 2)
        swap2(2, 0,  2, 2)
        if !right do transpose_4x4(&base.data)
    } else do return

    size := calc_size(base.data)
    base.width = size.x
    base.height = size.y

    if should_lockdown() {
        rotate(!right)
    }

}

drop :: proc() {
    using curr_piece

    for !should_lockdown() {
        pos.y += 1
    }
    pos.y -= 1
    handle_lockdown()

}

update_piece :: proc() {
    using curr_piece

    pos.y += 1
    
    if should_lockdown() {
        pos.y -= 1
        handle_lockdown();
    }

    if frame_count % 6 == 0 {
        // rotate(true)
    }

}


