pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VARIABLES DEL JUEGO
estado_juego = "inicio"
jugador = nil
enemigos = {}
flechas = {}
vidas = 3
puerta_abierta = false -- Nuevo estado para la puerta
mostrar_mensaje_victoria = false -- Para mostrar mensaje de victoria


-- ENTIDAD BASE
Entidad = {}
Entidad.__index = Entidad

function Entidad:Crear(x, y)
    local entidad = setmetatable({}, Entidad)
    entidad.x = x or 0
    entidad.y = y or 0
    entidad.ancho = 8
    entidad.alto = 8
    return entidad
end

-- FUNCION PARA INICIAR EL JUEGO
function iniciar_juego()
    vidas = 3
    jugador = Jugador:Crear()
    enemigos = {}
    for i = 1, 5 do
        add(enemigos, Enemigo:Crear())
    end
    flechas = {}
    puerta_abierta = false
    mostrar_mensaje_victoria = false
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
    local x_inicial = flr(MUNDO_ANCHO / 2) * TILE_SIZE
    local y_inicial = (MUNDO_ALTO - 2) * TILE_SIZE

    while mapa[flr(y_inicial / TILE_SIZE) + 1][flr(x_inicial / TILE_SIZE) + 1] == 32 do
        x_inicial += TILE_SIZE
    end

    local jugador = setmetatable(Personaje.Crear(self, x_inicial, y_inicial, 100), Jugador)
    return jugador
end

function Jugador:Morir()
    print("¡El jugador ha muerto!")
    estado_juego = "fin"
end

-- ENEMIGO
Enemigo = setmetatable({}, Personaje)
Enemigo.__index = Enemigo

function Enemigo:Crear()
    local x_aleatorio, y_aleatorio
    repeat
        x_aleatorio = flr(rnd(MUNDO_ANCHO - 2)) + 2
        y_aleatorio = flr(rnd(MUNDO_ALTO - 3)) + 2
    until mapa[y_aleatorio][x_aleatorio] ~= 32 and y_aleatorio ~= flr(jugador.y / TILE_SIZE) + 1

    local enemigo = setmetatable(Personaje.Crear(self, x_aleatorio * TILE_SIZE, y_aleatorio * TILE_SIZE, 50), Enemigo)
    enemigo.direccion = -1
    enemigo.velocidad = 1
    return enemigo
end

function Enemigo:Movimiento()
    local dx = self.direccion * self.velocidad
    local col_x = self.x + (self.direccion == -1 and 0 or self.ancho)
    if not ColisionConTerrenoCompleto(col_x + dx, self.y, self.ancho, self.alto) then
        self.x += dx
    else
        self.direccion *= -1
    end
    if self:ColisionConJugador() then
        Jugador:Morir()
    end
end

function Enemigo:ColisionConJugador()
    if self.x < jugador.x + jugador.ancho
            and self.x + self.ancho > jugador.x
            and self.y < jugador.y + jugador.alto
            and self.y + self.alto > jugador.y then
        vidas -= 1
        if vidas <= 0 then
            Jugador:Morir()
        end
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
    return flecha
end

function Flecha:Comportamiento()
    self.y -= self.velocidad
    if ColisionConTerrenoCompleto(self.x + (8 - self.ancho) / 2, self.y, self.ancho, self.alto) or ColisionConEnemigos(self) then
        self:Destruir()
    end
end

function Flecha:Destruir()
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
                mapa[y][x] = 32
            else
                mapa[y][x] = (rnd(1) < 0.1) and 32 or 16
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

-- FUNCIONES DE COLISIÓN
function ColisionConTerrenoCompleto(x, y, ancho, alto)
    local tile_x1 = flr(x / TILE_SIZE) + 1
    local tile_y1 = flr(y / TILE_SIZE) + 1
    local tile_x2 = flr((x + ancho - 1) / TILE_SIZE) + 1
    local tile_y2 = flr((y + alto - 1) / TILE_SIZE) + 1
    return (mapa[tile_y1] and (mapa[tile_y1][tile_x1] == 32 or mapa[tile_y1][tile_x2] == 32)) or
           (mapa[tile_y2] and (mapa[tile_y2][tile_x1] == 32 or mapa[tile_y2][tile_x2] == 32))
end

function ColisionConEnemigos(entidad)
    for enemigo in all(enemigos) do
        if entidad.x < enemigo.x + enemigo.ancho
                and entidad.x + entidad.ancho > enemigo.x
                and entidad.y < enemigo.y + enemigo.alto
                and entidad.y + entidad.alto > enemigo.y then
            enemigo:RecibirDanio()
            return true
        end
    end
    return false
end

function Enemigo:RecibirDanio()
    self.vida -= 10
    if self.vida <= 0 then
        self:Destruir()
    end
end

function Enemigo:Destruir()
    del(enemigos, self)
end

function VerificarAperturaPuerta()
    if #enemigos == 0 and not puerta_abierta then
        puerta_abierta = true
        local puerta_x1 = flr(MUNDO_ANCHO / 2)
        local puerta_x2 = puerta_x1 + 1
        local puerta_y = 1
        mapa[puerta_y][puerta_x1] = 16
        mapa[puerta_y][puerta_x2] = 16
    end
end

function VerificarVictoria()
    if puerta_abierta then
        -- Verificar si el jugador pasa por la puerta
        local puerta_x = flr(MUNDO_ANCHO / 2) * TILE_SIZE
        local puerta_y = 0 -- Parte superior del mapa (coordenada y)

        if jugador.x >= puerta_x and jugador.x <= puerta_x + TILE_SIZE
           and jugador.y <= puerta_y + TILE_SIZE then
            estado_juego = "victoria"
        end
    end
end

-- CICLO DEL JUEGO
function _init()
    Mundo:Generar()
    iniciar_juego()
end

function _update()
    if estado_juego == "inicio" then
        if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego()
        end
    elseif estado_juego == "jugando" then
        if btn(0) then jugador:Movimiento(-1, 0) end
        if btn(1) then jugador:Movimiento(1, 0) end
        if btn(2) then jugador:Movimiento(0, -1) end
        if btn(3) then jugador:Movimiento(0, 1) end

        if btnp(4) then
            add(flechas, Flecha:Crear(jugador.x, jugador.y, 3))
        end

        for flecha in all(flechas) do flecha:Comportamiento() end
        for enemigo in all(enemigos) do enemigo:Movimiento() end

        VerificarAperturaPuerta()
        VerificarVictoria()  -- Verificar si el jugador ha ganado

        if vidas <= 0 then
            estado_juego = "fin"
        end
    elseif estado_juego == "fin" then
        if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego()
        end
    elseif estado_juego == "victoria" then
        if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego()
        end
    end
end

function _draw()
    cls()
    if estado_juego == "inicio" then
        print("flechas y semillas", 40, 40, 7)
        print("pulsa x para comenzar", 30, 60, 7)
    elseif estado_juego == "jugando" then
        Mundo:Dibujar()
        spr(1, jugador.x, jugador.y)

        for enemigo in all(enemigos) do
            if enemigo.direccion == 1 then
                spr(5, enemigo.x + enemigo.ancho, enemigo.y, 1, 1, true)
            else    
                spr(5, enemigo.x, enemigo.y)
            end
        end

        for flecha in all(flechas) do
            spr(48, flecha.x, flecha.y)
        end

        for i = 1, vidas do
            spr(80, 8 * i, 8)
        end
    elseif estado_juego == "fin" then
        print("has muerto!", 50, 60, 8)
        print("pulsa x para reiniciar", 20, 80, 7)
    elseif estado_juego == "victoria" then
        print("¡Felicidades, ganaste!", 20, 50, 11)
        print("Pulsa x para reiniciar", 20, 80, 7)
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
