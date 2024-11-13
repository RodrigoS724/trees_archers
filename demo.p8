pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VARIABLES DEL JUEGO
estado_juego = "inicio"
jugador = nil
enemigos = {}
flechas = {}
vidas = 3
tiempo_entre_disparos = 0.3  -- tiempo entre disparos en segundos
tiempo_ultimo_disparo = 0     -- temporizador para controlar el delay
puerta_abierta = false -- Nuevo estado para la puerta
mostrar_mensaje_victoria = false -- Para mostrar mensaje de victoria
nivel_actual = 1

-- ENTIDAD BASE
Entidad = {
	x=10,
	y=20,
	ancho=8,
	alto=8,
}

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
    jugador.muerto = false

    for i = 1, 5 do
        add(enemigos, Enemigo:Crear())  -- enemigo tipo 1 (sprite 5)
    end
    
    -- agregar el nuevo enemigo tipo 2 segれむn el nivel
    if nivel_actual >= 2 then
        for i = 1, flr(nivel_actual / 2) do
            add(enemigos, enemigo_tipo2:crear())  -- enemigo tipo 2 (sprite 6)
        end
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
    jugador.invencible = false  -- estado de invencibilidad
    jugador.invencibilidad_tiempo = 0  -- temporizador para invencibilidad
    return jugador
end

function Jugador:Morir()
    -- aquれと puedes agregar animaciones o efectos de muerte
    print("el jugador ha muerto!")
    jugador.muerto = true
    estado_juego = "fin"  -- cambiar el estado del juego a "fin"
end

function Jugador:activar_invencibilidad()
    self.invencible = true
    self.invencibilidad_tiempo = 2  -- 2 segundos de invencibilidad, puedes ajustar esto
end

function Jugador:actualizar_invencibilidad()
    if self.invencible then
        self.invencibilidad_tiempo -= 1 / 30  -- reduce el tiempo cada frame (a 30 fps)
        if self.invencibilidad_tiempo <= 0 then
            self.invencible = false  -- desactivar la invencibilidad cuando se acabe el tiempo
        end
    end
end

-- ENEMIGO
Enemigo = setmetatable({}, Personaje)
Enemigo.__index = Enemigo

function Enemigo:Crear()
    local x_aleatorio, y_aleatorio
    local max_intentos = 100  -- nれむmero mれくximo de intentos para encontrar una posiciれはn vれくlida
    local intentos = 0

    repeat
        x_aleatorio = flr(rnd(MUNDO_ANCHO - 2)) + 2
        y_aleatorio = flr(rnd(MUNDO_ALTO - 3)) + 2
        intentos += 1

        -- verificar que la posiciれはn no estれた ocupada por un bloque sれはlido (32) y que sea accesible
    until mapa[y_aleatorio][x_aleatorio] ~= 32 and not ColisionConEnemigos({x = x_aleatorio, y = y_aleatorio, ancho = self.ancho, alto = self.alto}) and intentos < max_intentos

    -- si alcanzamos el lれとmite de intentos, damos por imposible el spawn
    if intentos == max_intentos then
        -- aquれと podemos implementar algれむn tipo de soluciれはn de fallback
        return nil
    end

    -- inicializamos las propiedades ancho y alto si no se han asignado
    self.ancho = self.ancho or 8  -- aれねadido
    self.alto = self.alto or 8    -- aれねadido

    -- si encontramos una posiciれはn vれくlida, generamos el enemigo
    local enemigo = setmetatable(Personaje.Crear(self, x_aleatorio * TILE_SIZE, y_aleatorio * TILE_SIZE, 50), Enemigo)
    enemigo.direccion = -1
    enemigo.velocidad = 1
    enemigo.sprite = 5
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
end

function Enemigo:ColisionConJugador()
    if self.x < jugador.x + jugador.ancho
        and self.x + self.ancho > jugador.x
        and self.y < jugador.y + jugador.alto
        and self.y + self.alto > jugador.y then
        if not jugador.muerto and not jugador.invencible then  -- verificar que no estれた muerto ni invencible
            vidas -= 1
            jugador:activar_invencibilidad()  -- activar invencibilidad temporal
            if vidas <= 0 then
                jugador:Morir()
            end
        end
        return true
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

-- nuevo tipo de enemigo que usa el sprite 6 y tiene mれくs vida y lれはgica de persecuciれはn
enemigo_tipo2 = setmetatable({}, Personaje)
enemigo_tipo2.__index = enemigo_tipo2

function enemigo_tipo2:crear()
    local x_aleatorio, y_aleatorio
    local max_intentos = 100
    local intentos = 0

    repeat
        x_aleatorio = flr(rnd(MUNDO_ANCHO - 2)) + 2
        y_aleatorio = flr(rnd(MUNDO_ALTO - 3)) + 2
        intentos += 1
    until mapa[y_aleatorio][x_aleatorio] ~= 32 
          and not ColisionConEnemigos({x = x_aleatorio, y = y_aleatorio, ancho = self.ancho, alto = self.alto}) 
          and intentos < max_intentos

    if intentos == max_intentos then
        return nil
    end
    
    self.ancho = self.ancho or 8  -- aれねadido
    self.alto = self.alto or 8
    local enemigo = setmetatable(Personaje.Crear(self, x_aleatorio * TILE_SIZE, y_aleatorio * TILE_SIZE, 100), enemigo_tipo2)
    enemigo.direccion = -1
    enemigo.velocidad = 1
    enemigo.sprite = 6  -- usa el sprite 6
    enemigo.vida = 100
    enemigo.rango_det = 32  -- rango en el que detecta al jugador
    enemigo.velocidad = 0.75  -- velocidad de persecuciれはn
    return enemigo
end

function enemigo_tipo2:Movimiento()
    local dx = jugador.x - self.x
    local dy = jugador.y - self.y
    local distancia = sqrt(dx^2 + dy^2)

				print("jugador x: " .. jugador.x .. ", y: " .. jugador.y)
				
    -- si el jugador estれく dentro del rango de detecciれはn, perseguir
    if distancia < self.rango_det then
        local dir_x = dx > 0 and 1 or -1
        local dir_y = dy > 0 and 1 or -1

        if abs(dx) > abs(dy) then
            if not ColisionConTerrenoCompleto(self.x + dir_x * self.velocidad, self.y, self.ancho, self.alto) then
                self.x += dir_x * self.velocidad
            end
        else
            if not ColisionConTerrenoCompleto(self.x, self.y + dir_y * self.velocidad, self.ancho, self.alto) then
                self.y += dir_y * self.velocidad
            end
        end
    end
end

function enemigo_tipo2:ColisionConJugador()
    if self.x < jugador.x + jugador.ancho
        and self.x + self.ancho > jugador.x
        and self.y < jugador.y + jugador.alto
        and self.y + self.alto > jugador.y then
        if not jugador.muerto and not jugador.invencible then  -- verificar que no estれた muerto ni invencible
            vidas -= 1
            jugador:activar_invencibilidad()  -- activar invencibilidad temporal
            if vidas <= 0 then
                jugador:Morir()
            end
        end
        return true
    end
    return false
end

function enemigo_tipo2:RecibirDanio()
    self.vida -= 10
    if self.vida <= 0 then
        self:Destruir()
    end
end

function enemigo_tipo2:Destruir()
    del(enemigos, self)
end

-- FLECHA
Flecha = setmetatable({}, Entidad)
Flecha.__index = Flecha

function Flecha:Crear(x, y, velocidad_x, velocidad_y)
    local flecha = setmetatable(Entidad.Crear(self, x, y), Flecha)
    flecha.velocidad_x = velocidad_x or 0
    flecha.velocidad_y = velocidad_y or 0
    flecha.ancho = 4
    return flecha
end

function Flecha:Comportamiento()
    self.x += self.velocidad_x
    self.y += self.velocidad_y
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
    -- redibujar la puerta si estれく abierta
    if puerta_abierta then
        local puerta_x1 = flr(MUNDO_ANCHO / 2)
        local puerta_x2 = puerta_x1 + 1
        local puerta_y = 1
        spr(16, puerta_x1 * TILE_SIZE, puerta_y * TILE_SIZE)
        spr(16, puerta_x2 * TILE_SIZE, puerta_y * TILE_SIZE)
    end
end

-- FUNCIONES DE COLISIれ⧗N
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
        local puerta_x = flr(MUNDO_ANCHO / 2) * TILE_SIZE
        local puerta_y = 0

        if jugador.x >= puerta_x and jugador.x <= puerta_x + TILE_SIZE and jugador.y <= puerta_y + TILE_SIZE then
            estado_juego = "victoria"
            mostrar_mensaje_victoria = true
        end
    end
end

function avanzar_nivel()
    nivel_actual += 1
    Mundo:Generar()
    iniciar_juego()
    estado_juego = "jugando"
end

-- CICLO DEL JUEGO
function _init()
    Mundo:Generar()
    iniciar_juego()
end

function _update()
				if jugador.muerto then
								if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego()
        end
				end
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

								jugador:actualizar_invencibilidad()
								
        -- verificar si ha pasado el tiempo suficiente para disparar
        tiempo_ultimo_disparo += 1 / 30  -- contamos el tiempo (30 fps)
        
        if btnp(4) and tiempo_ultimo_disparo >= tiempo_entre_disparos then
            -- lれはgica para disparar
            if btn(0) then -- izquierda
                add(flechas, Flecha:Crear(jugador.x, jugador.y, -3, 0)) -- dispara a la izquierda
            elseif btn(1) then -- derecha
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 3, 0)) -- dispara a la derecha
            elseif btn(2) then -- arriba
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 0, -3)) -- dispara arriba
            elseif btn(3) then -- abajo
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 0, 3)) -- dispara abajo
            else
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 0, -3)) -- por defecto dispara arriba
            end
            -- reiniciar el temporizador
            tiempo_ultimo_disparo = 0
        end

        -- actualizar flechas y enemigos
        for flecha in all(flechas) do flecha:Comportamiento() end
								for enemigo in all(enemigos) do
								    enemigo:Movimiento()
								    enemigo:ColisionConJugador()  -- agrega esta lれとnea
								end

        -- verificar la victoria
        VerificarAperturaPuerta()
        VerificarVictoria()

        -- verificar si el jugador muere
        if vidas <= 0 then
            estado_juego = "fin"
        end
    elseif estado_juego == "fin" then
        if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego()
        end
    elseif estado_juego == "victoria" then
        if mostrar_mensaje_victoria then
            print("るくfelicitaciones! nivel completado.")
            -- esperar un botれはn para avanzar al siguiente nivel
            if btnp(4) or btnp(5) then
                mostrar_mensaje_victoria = false
                avanzar_nivel()
            end
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
        if jugador.invencible then
            -- mostrar el jugador de forma diferente si estれく invencible (p. ej., cambiando de color)
            spr(1, jugador.x, jugador.y, 1, 1, true)  -- cambio de sprite
        else
            spr(1, jugador.x, jugador.y)
        end
        
        for enemigo in all(enemigos) do
            if enemigo.direccion == 1 then
                spr(enemigo.sprite, enemigo.x + enemigo.ancho, enemigo.y, 1, 1, true)
            else    
                spr(enemigo.sprite, enemigo.x, enemigo.y)
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
        print("るくFelicidades, ganaste!", 20, 50, 11)
        print("toca algun boton para ", 20, 80, 7);
        print("continuar al", 20, 90, 7);
        print("siguiente nivel", 20, 100, 7);
    end
end
__gfx__
00000000000aa0000000000000000000000000000000330000880880000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000000000000000000000000000003300000888880003333000000000000000000000000000000000000000000000000000000000000000000
007007000a5aa5a000000000000000000000000000088007088a8a88033883300000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaa0000000000000000000000000088880d08888888338858330000000000000000000000000000000000000000000000000000000000000000
00077000aa5aa5aa0000000000000000000000000088880d08844488385888830000000000000000000000000000000000000000000000000000000000000000
007007000aa55aa00000000000000000000000000008885d08448448338858330000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000000000000000000000000000008880d00888880033883300000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000000000000000000000000000088800d00880880003333000000000000000000000000000000000000000000000000000000000000000000
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
00004000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
