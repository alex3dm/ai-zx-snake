; ============================================
; SNAKE FOR ZX SPECTRUM 48K - CORRECT GRAPHICS
; ============================================
; Assemble: pasmo --tapbas snake.asm snake.tap
; Run:      LOAD "" CODE : RANDOMIZE USR 32768
; ============================================

        ORG 32768

; --- Константы ---
SCR_BASE    EQU 16384
ATTR_BASE   EQU 22528
FRAMES      EQU 23672

MAX_LEN     EQU 80

; ============================================
; ТОЧКА ВХОДА
; ============================================
start:
        ei
        ld sp, stack_top

        call cls_screen

        ; --- Инициализация змейки ---
        ld a, 16
        ld (head_x), a
        ld a, 12
        ld (head_y), a
        ld a, 3
        ld (direction), a
        ld a, 3
        ld (snake_len), a
        ld a, 5
        ld (speed), a
        ld (speed_counter), a
        xor a
        ld (ate_food), a
        ld (score), a

        ; Заполняем тело змейки (3 сегмента)
        ld hl, snake_body
        ld (hl), 16
        inc hl
        ld (hl), 12
        inc hl
        ld (hl), 15
        inc hl
        ld (hl), 12
        inc hl
        ld (hl), 14
        inc hl
        ld (hl), 12

        call draw_all
        call place_food
        call draw_food_item
        call show_score

; ============================================
; ГЛАВНЫЙ ЦИКЛ
; ============================================
game_loop:
        halt
        call read_keys

        ld a, (speed_counter)
        dec a
        ld (speed_counter), a
        jr nz, game_loop

        ld a, (speed)
        ld (speed_counter), a

        call move_snake
        jp game_loop

; ============================================
; ДВИЖЕНИЕ
; ============================================
move_snake:
        ld a, (head_x)
        ld (old_head_x), a
        ld a, (head_y)
        ld (old_head_y), a

        ld a, (direction)
        cp 0
        jr z, go_up
        cp 1
        jr z, go_down
        cp 2
        jr z, go_left
        ld a, (head_x)
        inc a
        ld (head_x), a
        jr check_walls
go_up:
        ld a, (head_y)
        dec a
        ld (head_y), a
        jr check_walls
go_down:
        ld a, (head_y)
        inc a
        ld (head_y), a
        jr check_walls
go_left:
        ld a, (head_x)
        dec a
        ld (head_x), a

check_walls:
        ld a, (head_x)
        cp 32
        jp nc, game_over
        ld a, (head_y)
        cp 24
        jp nc, game_over

        call check_self
        jp z, game_over

        call check_food
        jr z, got_food

        call erase_tail
        jr do_shift

got_food:
        ld hl, snake_len
        inc (hl)
        ld a, (hl)
        cp MAX_LEN
        jp nc, game_over

        xor a
        ld (ate_food), a

        ld hl, score
        inc (hl)
        call show_score

        ld a, (score)
        ld b, 5
        call div10_b
        ld a, h
        or a
        jr z, no_speedup
        ld a, (speed)
        cp 2
        jr z, no_speedup
        dec a
        ld (speed), a
no_speedup:
        call place_food
        call draw_food_item
        call beep_eat

do_shift:
        call shift_body

        ld hl, snake_body
        ld a, (old_head_x)
        ld (hl), a
        inc hl
        ld a, (old_head_y)
        ld (hl), a

        ld a, (head_x)
        ld d, a
        ld a, (head_y)
        ld e, a
        call draw_block
        ret

; ============================================
; РИСОВАНИЕ БЛОКА 8×8 (СПЛОШНОЙ)
; Вход: D=X(0-31), E=Y(0-23)
; ============================================
draw_block:
        call calc_screen_addr
        ld b, 8           ; 8 строк
draw_block_loop:
        ld (hl), 255      ; Сплошная строка (8 белых пикселей)
        call next_line
        dec b
        jr nz, draw_block_loop
        ret

; ============================================
; РИСОВАНИЕ КРЕСТА 8×8 (ЕДА)
; Вход: D=X(0-31), E=Y(0-23)
; ============================================
draw_cross:
        call calc_screen_addr
        ld b, 8
        ld de, cross_pattern
draw_cross_loop:
        ld a, (de)
        ld (hl), a
        inc de
        call next_line
        dec b
        jr nz, draw_cross_loop
        ret

cross_pattern:
        DEFB 0, 36, 24, 60, 60, 24, 36, 0

; ============================================
; СТИРАНИЕ БЛОКА 8×8
; Вход: D=X(0-31), E=Y(0-23)
; ============================================
erase_block:
        call calc_screen_addr
        ld b, 8
erase_block_loop:
        ld (hl), 0        ; Пустая строка
        call next_line
        dec b
        jr nz, erase_block_loop
        ret

; ============================================
; ПЕРЕХОД К СЛЕДУЮЩЕЙ СТРОКЕ СИМВОЛА
; ============================================
next_line:
        inc h
        ld a, h
        and 7
        ret nz
        ld a, l
        add a, 32
        ld l, a
        ret nc
        ld a, h
        sub 8
        ld h, a
        ret

; ============================================
; СТИРАНИЕ ХВОСТА
; ============================================
erase_tail:
        ld a, (snake_len)
        dec a
        call get_body_addr
        ld a, (hl)
        ld d, a
        inc hl
        ld a, (hl)
        ld e, a
        call erase_block
        ret

; ============================================
; СДВИГ ТЕЛА
; ============================================
shift_body:
        ld a, (snake_len)
        dec a
        ret z

        ld b, 0
        ld c, a
        add a, a
        ld c, a
        jr nc, no_carry_bc
        inc b
no_carry_bc:
        push bc

        pop bc
        push bc
        ld h, 0
        ld l, c
        ld de, snake_body
        add hl, de
        dec hl

        ld d, h
        ld e, l
        inc de
        inc de

        pop bc
        lddr
        ret

; ============================================
; АДРЕС ЭЛЕМЕНТА ТЕЛА
; ============================================
get_body_addr:
        ld l, a
        ld h, 0
        add hl, hl
        ld de, snake_body
        add hl, de
        ret

; ============================================
; ПРОВЕРКА СТОЛКНОВЕНИЯ
; ============================================
check_self:
        ld a, (snake_len)
        dec a
        ret z
        ld b, a
        ld hl, snake_body

self_loop:
        ld a, (head_x)
        cp (hl)
        jr nz, self_next
        inc hl
        ld a, (head_y)
        cp (hl)
        ret z
        dec hl
self_next:
        inc hl
        inc hl
        djnz self_loop
        or 1
        ret

; ============================================
; ПРОВЕРКА ЕДЫ
; ============================================
check_food:
        ld a, (head_x)
        ld b, a
        ld a, (food_x)
        cp b
        ret nz
        ld a, (head_y)
        ld b, a
        ld a, (food_y)
        cp b
        ret nz
        ld a, 1
        ld (ate_food), a
        ret

; ============================================
; РАЗМЕЩЕНИЕ ЕДЫ
; ============================================
place_food:
place_retry:
        ld hl, FRAMES
        ld a, (hl)
        inc hl
        xor (hl)
        and 31
        ld (food_x), a

        ld hl, FRAMES
        inc hl
        inc hl
        ld a, (hl)
        dec hl
        xor (hl)
        and 23
        ld (food_y), a

        call food_on_snake
        jr z, place_retry
        ret

food_on_snake:
        ld a, (snake_len)
        ld b, a
        ld hl, snake_body
food_loop:
        ld a, (food_x)
        cp (hl)
        jr nz, food_next
        inc hl
        ld a, (food_y)
        cp (hl)
        ret z
        dec hl
food_next:
        inc hl
        inc hl
        djnz food_loop
        or 1
        ret

; ============================================
; ОТРИСОВКА ВСЕЙ ЗМЕЙКИ
; ============================================
draw_all:
        ld a, (snake_len)
        ld b, a
        ld hl, snake_body
draw_loop:
        push bc
        push hl
        ld a, (hl)
        ld d, a
        inc hl
        ld a, (hl)
        ld e, a
        call draw_block
        pop hl
        inc hl
        inc hl
        pop bc
        djnz draw_loop
        ret

draw_food_item:
        ld a, (food_x)
        ld d, a
        ld a, (food_y)
        ld e, a
        call draw_cross
        ret

; ============================================
; РАСЧЁТ АДРЕСА ЭКРАНА
; ============================================
calc_screen_addr:
        ld a, e
        and 24
        or 64
        ld h, a
        ld a, e
        and 7
        rlca
        rlca
        rlca
        rlca
        rlca
        or d
        ld l, a
        ret

; ============================================
; КЛАВИАТУРА
; ============================================
read_keys:
        ld bc, $fbfe
        in a, (c)
        bit 0, a
        jr nz, try_down
        ld a, (direction)
        cp 1
        jr z, try_down
        xor a
        ld (direction), a
        ret

try_down:
        ld bc, $fdfe
        in a, (c)
        bit 0, a
        jr nz, try_left
        ld a, (direction)
        cp 0
        jr z, try_left
        ld a, 1
        ld (direction), a
        ret

try_left:
        ld bc, $dffe
        in a, (c)
        bit 1, a
        jr nz, try_right
        ld a, (direction)
        cp 3
        jr z, try_right
        ld a, 2
        ld (direction), a
        ret

try_right:
        ld bc, $dffe
        in a, (c)
        bit 0, a
        jr nz, keys_done
        ld a, (direction)
        cp 2
        jr z, keys_done
        ld a, 3
        ld (direction), a
keys_done:
        ret

; ============================================
; ОЧИСТКА ЭКРАНА
; ============================================
cls_screen:
        ld hl, SCR_BASE
        ld (hl), 0
        ld de, SCR_BASE + 1
        ld bc, 6143
        ldir

        ld hl, ATTR_BASE
        ld (hl), 56
        ld de, ATTR_BASE + 1
        ld bc, 767
        ldir
        ret

; ============================================
; ПОКАЗАТЬ СЧЁТ
; ============================================
show_score:
        ld a, 22
        rst 16
        xor a
        rst 16
        xor a
        rst 16

        ld hl, txt_score
        call print_str

        ld a, (score)
        call print_num
        ret

txt_score:
        DEFB "SCORE: ", 0

print_str:
        ld a, (hl)
        or a
        ret z
        rst 16
        inc hl
        jr print_str

print_num:
        ld b, 10
        call div10_b
        ld c, a
        ld a, h
        add a, '0'
        rst 16
        ld a, c
        add a, '0'
        rst 16
        ret

div10_b:
        ld h, 0
div10_loop:
        cp b
        jr c, div10_done
        sub b
        inc h
        jr div10_loop
div10_done:
        ret

; ============================================
; ЗВУК
; ============================================
beep_eat:
        ld b, 20
beep_lp:
        ld a, 16
        out ($fe), a
        ld c, 15
beep_d1:
        dec c
        jr nz, beep_d1
        xor a
        out ($fe), a
        ld c, 15
beep_d2:
        dec c
        jr nz, beep_d2
        djnz beep_lp
        ret

; ============================================
; GAME OVER
; ============================================
game_over:
        ld b, 80
die_lp:
        ld a, 16
        out ($fe), a
        ld c, 60
die_d1:
        dec c
        jr nz, die_d1
        xor a
        out ($fe), a
        ld c, 60
die_d2:
        dec c
        jr nz, die_d2
        djnz die_lp

        ld a, 22
        rst 16
        ld a, 11
        rst 16
        ld a, 5
        rst 16
        ld hl, txt_gameover
        call print_str

wait_key:
        halt
        ld bc, $7ffe
        in a, (c)
        bit 0, a
        jr nz, wait_key

        jp start

txt_gameover:
        DEFB "GAME OVER! PRESS SPACE", 0

; ============================================
; ДАННЫЕ
; ============================================
head_x:         DEFB 0
head_y:         DEFB 0
old_head_x:     DEFB 0
old_head_y:     DEFB 0
direction:      DEFB 3
snake_len:      DEFB 3
ate_food:       DEFB 0
food_x:         DEFB 0
food_y:         DEFB 0
score:          DEFB 0
speed:          DEFB 5
speed_counter:  DEFB 5

snake_body:     DEFS MAX_LEN * 2

                DEFS 64
stack_top:

        END start