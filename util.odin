package main

import "core:strings"
import "core:slice"
import "core:unicode/utf8"
import "core:reflect"

@(private="file") piece_states : [dynamic] [] Palette
append_piece_state :: proc(data: [] Palette) {
    cloned, _ := slice.clone(data)
    append(&piece_states, cloned) 
}

log_accumulated_states :: proc() {
    b : [4] strings.Builder

    for ln in 0..<4 {
        for state in piece_states {
            strings.write_string(&b[ln], "[ ")
            for i in 0..<4 {
                cell := utf8.rune_at(reflect.enum_string(state[ln * 4 + i]), 0)
                strings.write_rune(&b[ln], cell if cell != 'N' else ' ')
                strings.write_rune(&b[ln], ' ')
            }
            strings.write_string(&b[ln], "]  ")
        }
    }


    for line in b {
        logln(strings.to_string(line))
    }
    logln()

    clear(&piece_states)

}
// TODO: temp
array_to_matrix :: proc(array: [4*4] Palette) -> (mat: matrix[4, 4] u8) {
    for i in 0..<4 {
        for j in 0..<4 {
            mat[i, j] = u8(array[i * 4 + j])
        }
    }
    return
}

transpose_4x4 :: proc(mat: ^[4][4] Palette) {
        temp: [4][4] Palette
        for i in 0..<4 {
            for j in 0..<4 {
                // temp[j * 4 + i] = base.data[i * 4 + j]
                temp[j][i] = mat^[i][j]
            }
        } 
        for i in 0..<4 do mat^[i].xyzw = temp[i].xyzw
}


Delayed :: struct {
    func: proc() -> (blocking: bool),
    tick: int     // absolute tick the func should be called on.
}

delayed_funcs : [dynamic] Delayed

do_later :: proc(func: proc() -> (blocking: bool), skip: int) {
    append_elem(&delayed_funcs, Delayed { func, skip + tick_count })
}

handle_delayed_funcs :: proc() -> (blocking: bool) {
    #reverse for f, i in delayed_funcs {
        if f.tick == tick_count {
            blocking ||= f.func()
            unordered_remove(&delayed_funcs, i)
        }
    }
    return
}
