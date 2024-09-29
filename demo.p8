pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function _init()
    player_x = 8
    player_y = 120
    size_chunk = 8
    sprite_player = 1
    screen_size_x = 128
    screen_size_y = 128
end

function _update()
    if btnp(0) then
        -- left
        if player_x > 0 then
            player_x -= size_chunk
        end
    end
    if btnp(1) then
        -- right
        if player_x < screen_size_x - size_chunk then
            player_x += size_chunk
        end
    end
    if btnp(2) then
        -- up
        if player_y > 0  then
            player_y -= size_chunk
        end
    end
    if btnp(3) then
        -- down
        if player_y < screen_size_y - size_chunk then
            player_y += size_chunk
        end
    end
end

function _draw()
    cls()
    spr(sprite_player, player_x, player_y)
end

__gfx__
00000000000aa0000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000000000000000000000000000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000a0aa0a00000000000000000000000000008800700000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000a9aaaa9a0000000000000000000000000088880d00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa0000000000000000000000000088880d00000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaa009aa0000000000000000000000000008885d00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00000000000000000000000000008880d00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000000000000000000000000000088800d00000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44445444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00338300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33383333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
38333338000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00064600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
