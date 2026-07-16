package main

import rl "vendor:raylib"

Action :: enum {
    LEFT,
    RIGHT,
    ROTATE_LEFT,
    ROTATE_RIGHT,

    DROP_HARD,
    DROP_SONIC,
    TOGGLE_PAUSE,
    FULLSCREEN,
}

actions : [Action] [] rl.KeyboardKey 

handle_key_press :: proc() {
    for action, i in actions {
        for keybind in action {
            if rl.IsKeyReleased(keybind) {
                handle_action(Action(i))
            }
        }
    }
}

handle_action :: proc(action: Action) {
    switch action {
        case .LEFT:  move(true)
        case .RIGHT: move(false)
        case .ROTATE_LEFT:  rotate(false)
        case .ROTATE_RIGHT: rotate(true)
        
        case .DROP_HARD:    drop(hard = true)
        case .DROP_SONIC:   drop(hard = false)

        case .TOGGLE_PAUSE: logln("NYI")
        case .FULLSCREEN:   logln("NYI")
    }

}
