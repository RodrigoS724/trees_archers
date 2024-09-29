pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- ENTIDAD BASE
Entidad = {}
Entidad.__index = Entidad

function Entidad:Crear(x, y)
    local entidad = setmetatable({}, Entidad)
    entidad.x = x or 0
    entidad.y = y or 0
    return entidad
end

-- PERSONAJE
Personaje = setmetatable({}, Entidad)
Personaje.__index = Personaje

function Personaje:Crear(x, y, vida)
    local personaje = setmetatable(Entidad.Crear(self, x, y), Personaje)
    personaje.vida = vida or 100
    return personaje
end

function Personaje:Movimiento(dx, dy)
    self.x += dx
    self.y += dy
end

-- JUGADOR
Jugador = setmetatable({}, Personaje)
Jugador.__index = Jugador

function Jugador:Crear(x, y)
    local jugador = setmetatable(Personaje.Crear(self, x, y, 100), Jugador)
    return jugador
end

-- ENEMIGO
Enemigo = setmetatable({}, Personaje)
Enemigo.__index = Enemigo

function Enemigo:Crear(x, y)
    local enemigo = setmetatable(Personaje.Crear(self, x, y, 50), Enemigo)
    return enemigo
end

-- FLECHA
Flecha = setmetatable({}, Entidad)
Flecha.__index = Flecha

function Flecha:Crear(x, y, velocidad)
    local flecha = setmetatable(Entidad.Crear(self, x, y), Flecha)
    flecha.velocidad = velocidad or 2
    return flecha
end

function Flecha:Comportamiento()
    self.y -= self.velocidad
end

-- MUNDO
Mundo = {}
Mundo.__index = Mundo

-- Dimensiones del mapa (por ejemplo, 16x16 tiles)
MUNDO_ANCHO = 16
MUNDO_ALTO = 16
TILE_SIZE = 8

-- Constructor de Mundo
function Mundo:Generar()
    -- Inicializa el mapa
    mapa = {}
    for y = 1, MUNDO_ALTO do
        mapa[y] = {}
        for x = 1, MUNDO_ANCHO do
            if x == 1 or x == MUNDO_ANCHO or y == 1 or y == MUNDO_ALTO then
                -- Periferia del mapa con れくrboles (sprite 32)
                mapa[y][x] = 32
            else
                -- Aれねade terreno (sprite 16) con posibilidad de れくrboles
                if rnd(1) < 0.1 then
                    mapa[y][x] = 32  -- れ▒rbol disperso
                else
                    mapa[y][x] = 16  -- Terreno
                end
            end
        end
    end
end

-- Dibuja el mapa
function Mundo:Dibujar()
    for y = 1, MUNDO_ALTO do
        for x = 1, MUNDO_ANCHO do
            spr(mapa[y][x], (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
        end
    end
end

-- SPRITES
function CargarSprites()
    -- Cargar sprites especれとficos, ya configurados:
    -- 1: Jugador, 5: Enemigo, 16: Terreno, 32: れ▒rbol, 48: Flecha
end

-- CICLO DEL JUEGO
jugador = Jugador:Crear(10, 10)
enemigos = {Enemigo:Crear(20, 30), Enemigo:Crear(50, 70)}
flechas = {}

function _init()
    Mundo:Generar()
    CargarSprites()
end

function _update()
    -- Actualizar jugador
    if btn(0) then jugador:Movimiento(-1, 0) end
    if btn(1) then jugador:Movimiento(1, 0) end
    if btn(2) then jugador:Movimiento(0, -1) end
    if btn(3) then jugador:Movimiento(0, 1) end

    -- Disparar
    if btnp(4) then
        add(flechas, Flecha:Crear(jugador.x, jugador.y, 3))
    end

    -- Actualizar flechas
    for flecha in all(flechas) do
        flecha:Comportamiento()
    end

    -- Lれはgica de enemigos y colisiones (pendiente)
end

function _draw()
    cls()
    -- Dibujar el mapa
    Mundo:Dibujar()
    
    -- Dibujar jugador
    spr(1, jugador.x, jugador.y)
    
    -- Dibujar enemigos
    for enemigo in all(enemigos) do
        spr(5, enemigo.x, enemigo.y)
    end

    -- Dibujar flechas
    for flecha in all(flechas) do
        spr(48, flecha.x, flecha.y)
    end
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
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff5fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f5ffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff5f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff5ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff5fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff3383ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f333333f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33383333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
38333338000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f333333f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff445ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff44fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff44fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
