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
    entidad.ancho = 8
    -- Tamaれねo en pれとxeles
    entidad.alto = 8
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

-- Movimiento del personaje con colisiれはn en todo el sprite (AABB)
function Personaje:Movimiento(dx, dy)
    local nuevo_x = self.x + dx
    local nuevo_y = self.y + dy
    if not ColisionConTerrenoCompleto(nuevo_x, nuevo_y, self.ancho, self.alto) then
        self.x = nuevo_x
        self.y = nuevo_y
    end
end

-- JUGADOR
Jugador = setmetatable({}, Personaje)
Jugador.__index = Jugador

function Jugador:Crear()
    -- Posiciれはn inicial en el centro inferior del mapa
    local x_inicial = flr(MUNDO_ANCHO / 2) * TILE_SIZE
    local y_inicial = (MUNDO_ALTO - 2) * TILE_SIZE -- Segunda fila desde abajo

    -- Evitar que el jugador aparezca sobre un れくrbol
    while mapa[flr(y_inicial / TILE_SIZE) + 1][flr(x_inicial / TILE_SIZE) + 1] == 32 do
        x_inicial += TILE_SIZE -- Mover a la derecha hasta encontrar terreno libre
    end

    local jugador = setmetatable(Personaje.Crear(self, x_inicial, y_inicial, 100), Jugador)
    return jugador
end


function Jugador:Morir()
    -- Lれはgica para morir (puedes definir cれはmo quieres manejar esto)
    print("るくEl jugador ha muerto!")
    -- Aquれと puedes aれねadir mれくs lれはgica, como reiniciar el juego
end

-- ENEMIGO
Enemigo = setmetatable({}, Personaje)
Enemigo.__index = Enemigo

function Enemigo:Crear()
    local enemigo
    local x_aleatorio, y_aleatorio

    -- Generar una posiciれはn aleatoria para el enemigo
    repeat
        x_aleatorio = flr(rnd(MUNDO_ANCHO - 2)) + 2 -- Dentro del rango del mapa
        y_aleatorio = flr(rnd(MUNDO_ALTO - 3)) + 2 -- Evitar las bordes y la lれとnea del jugador

        -- Evitar que el enemigo aparezca sobre un れくrbol y en la misma lれとnea que el jugador
    until mapa[y_aleatorio][x_aleatorio] ~= 32 and y_aleatorio ~= flr(jugador.y / TILE_SIZE) + 1

    enemigo = setmetatable(Personaje.Crear(self, x_aleatorio * TILE_SIZE, y_aleatorio * TILE_SIZE, 50), Enemigo)
    enemigo.direccion = -1 -- Inicia moviれたndose hacia la izquierda
    enemigo.velocidad = 1 -- Velocidad de movimiento
    return enemigo
end


function Enemigo:Movimiento()
    -- Mover en la dirección actual
    local dx = self.direccion * self.velocidad

    -- Ajustar la posición de colisión según la dirección del enemigo
    local col_x = self.x + (self.direccion == -1 and 0 or self.ancho)

    -- Colisión con el terreno usando el borde del sprite
    if not ColisionConTerrenoCompleto(col_x + dx, self.y, self.ancho, self.alto) then
        self.x += dx
    else
        -- Cambiar de dirección al colisionar
        self.direccion *= -1
    end

    -- Verificar colisión con el jugador
    if self:ColisionConJugador() then
        Jugador:Morir() -- Llamar a la función de morir del jugador
    end
end


function Enemigo:ColisionConJugador()
    if self.x < jugador.x + jugador.ancho
            and self.x + self.ancho > jugador.x
            and self.y < jugador.y + jugador.alto
            and self.y + self.alto > jugador.y then
        return true
    end
    return false
end

-- FLECHA
Flecha = setmetatable({}, Entidad)
Flecha.__index = Flecha

function Flecha:Crear(x, y, velocidad)
    local flecha = setmetatable(Entidad.Crear(self, x, y), Flecha)
    flecha.velocidad = velocidad or 2
    flecha.ancho = 4
    -- Ancho de colisiれはn reducido
    return flecha
end

function Flecha:Comportamiento()
    self.y -= self.velocidad
    -- Si la flecha colisiona con un れくrbol o enemigo, desaparece
    if ColisionConTerrenoCompleto(self.x + (8 - self.ancho) / 2, self.y, self.ancho, self.alto) or ColisionConEnemigos(self) then
        self:Destruir()
    end
end

function Flecha:Destruir()
    -- Elimina la flecha de la lista de flechas
    del(flechas, self)
end

-- MUNDO
Mundo = {}
Mundo.__index = Mundo

MUNDO_ANCHO = 16
MUNDO_ALTO = 16
TILE_SIZE = 8

function Mundo:Generar()
    mapa = {}
    for y = 1, MUNDO_ALTO do
        mapa[y] = {}
        for x = 1, MUNDO_ANCHO do
            if x == 1 or x == MUNDO_ANCHO or y == 1 or y == MUNDO_ALTO then
                mapa[y][x] = 32 -- れ▒rboles en la periferia
            else
                if rnd(1) < 0.1 then
                    mapa[y][x] = 32 -- れ▒rbol disperso
                else
                    mapa[y][x] = 16 -- Terreno
                end
            end
        end
    end
end

function Mundo:Dibujar()
    for y = 1, MUNDO_ALTO do
        for x = 1, MUNDO_ANCHO do
            spr(mapa[y][x], (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
        end
    end
end

-- FUNCIONES DE COLISIれ⧗N

-- Verifica si una posiciれはn (x, y, ancho, alto) estれく colisionando con un れくrbol en cualquier parte del sprite (AABB)
function ColisionConTerrenoCompleto(x, y, ancho, alto)
    local tile_x1 = flr(x / TILE_SIZE) + 1
    local tile_y1 = flr(y / TILE_SIZE) + 1
    local tile_x2 = flr((x + ancho - 1) / TILE_SIZE) + 1
    local tile_y2 = flr((y + alto - 1) / TILE_SIZE) + 1

    if mapa[tile_y1] and (mapa[tile_y1][tile_x1] == 32 or mapa[tile_y1][tile_x2] == 32) then
        return true
    end

    if mapa[tile_y2] and (mapa[tile_y2][tile_x1] == 32 or mapa[tile_y2][tile_x2] == 32) then
        return true
    end

    return false
end

-- Verifica si una entidad (como una flecha) colisiona con un enemigo
function ColisionConEnemigos(entidad)
    for enemigo in all(enemigos) do
        if entidad.x < enemigo.x + enemigo.ancho
                and entidad.x + entidad.ancho > enemigo.x
                and entidad.y < enemigo.y + enemigo.alto
                and entidad.y + entidad.alto > enemigo.y then
            -- Colisiona con el enemigo
            enemigo:RecibirDanio()
            return true
        end
    end
    return false
end

-- Sistema de daれねo para enemigos
function Enemigo:RecibirDanio()
    self.vida -= 10
    if self.vida <= 0 then
        self:Destruir()
    end
end

function Enemigo:Destruir()
    del(enemigos, self)
end

-- CICLO DEL JUEGO
jugador = nil
enemigos = {}
flechas = {}

function _init()
    -- Generar el mapa antes de crear al jugador
    Mundo:Generar()

    -- Crear al jugador despuれたs de generar el mapa
    jugador = Jugador:Crear()

    -- Crear una lista de enemigos en posiciones aleatorias
    for i = 1, 5 do  -- Puedes cambiar el nれむmero de enemigos
        add(enemigos, Enemigo:Crear())
    end
end



-- Verifica si todos los enemigos han sido eliminados
function VerificarAperturaPuerta()
    if #enemigos == 0 then
        -- Eliminar dos れくrboles (tiles con valor 32) en la parte superior central
        local puerta_x1 = flr(MUNDO_ANCHO / 2) -- Posiciれはn x del primer れくrbol
        local puerta_x2 = puerta_x1 + 1 -- Posiciれはn x del segundo れくrbol
        local puerta_y = 1 -- Parte superior del mapa (lれとnea 1)

        -- Cambiar los れくrboles por terreno (tile con valor 16)
        mapa[puerta_y][puerta_x1] = 16
        mapa[puerta_y][puerta_x2] = 16
    end
end

-- Actualiza la funciれはn de _update para verificar si se debe abrir la puerta

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

    -- Actualizar enemigos
    for enemigo in all(enemigos) do
        enemigo:Movimiento() -- Mover enemigo
    end

    -- Verificar si todos los enemigos han sido eliminados para abrir la puerta
    VerificarAperturaPuerta()
end


function _draw()
    cls()
    -- Dibujar el mapa
    Mundo:Dibujar()

    -- Dibujar jugador
    spr(1, jugador.x, jugador.y)

    -- Dibujar enemigos
    for enemigo in all(enemigos) do
        -- Invertir el sprite dependiendo de la direcciれはn
        if enemigo.direccion == 1 then
            spr(5, enemigo.x + enemigo.ancho, enemigo.y, 1, 1, true) -- Sprite mirando a la izquierda
          else    
            spr(5, enemigo.x, enemigo.y) -- Sprite mirando a la derecha
         end
    end

    -- Dibujar flechas
    for flecha in all(flechas) do
        spr(48, flecha.x, flecha.y)
    end
end


__gfx__
00000000000aa0000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000000000000000000000000000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000a5aa5a00000000000000000000000000008800700000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa0000000000000000000000000088880d00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aa5aa5aa0000000000000000000000000088880d00000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000aa55aa00000000000000000000000000008885d00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000000000000000000000000000008880d00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000000000000000000000000000088800d00000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff5fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f5ffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffff5f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff5ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffff5fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004333400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004434400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f00ff00f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f088880f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff0880ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff00fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
