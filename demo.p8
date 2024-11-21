pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VARIABLES DEL JUEGO
estado_juego = "inicio"
jugador = nil
enemigos = {}
flechas = {}
recolectables = {}
vidas = 3
tiempo_entre_disparos = 0.3 -- tiempo entre disparos en segundos
tiempo_ultimo_disparo = 0 -- temporizador para controlar el delay
aumento_vel_ataque = false
tiempo_aumento_vel_ataque = 0
puerta_abierta = false -- Nuevo estado para la puerta
mostrar_mensaje_victoria = false -- Para mostrar mensaje de victoria
nivel_actual = 1
curas_recogidas = 0 -- contador de curas recogidas
tiempo_mostrar_cura = 0 -- temporizador para mostrar el +1
aumento_recodigos = 0
tiempo_mostrar_aumento = 0

-- ENTIDAD BASE
Entidad = {
    x = 10,
    y = 20,
    ancho = 8,
    alto = 8
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
    if es_nuevo_juego then
        vidas = 3
    end

    jugador = Jugador:Crear()

    -- reiniciar la tabla global de enemigos
    enemigos = {}
    local total_enemigos = 5 + nivel_actual
    -- aumenta la cantidad total de enemigos con el nivel

    -- calcular proporciれはn de enemigos tipo 1 y tipo 2
    local prob_tipo1 = max(0.8 - (nivel_actual * 0.05), 0.3)
    -- tipo 1 predomina en niveles bajos
    local prob_tipo2 = 1 - prob_tipo1
    -- tipo 2 incrementa en niveles altos

    for i = 1, total_enemigos do
        if rnd(1) < prob_tipo1 then
            -- generar enemigo tipo 1
            local enemigo = Enemigo:Crear()
            if enemigo then add(enemigos, enemigo) end
        else
            -- generar enemigo tipo 2
            local enemigo = enemigo_tipo2:crear()
            if enemigo then add(enemigos, enemigo) end
        end
    end

    -- inicializar otras variables del juego
    jugador.muerto = false
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
    jugador.invencible = false
    -- estado de invencibilidad
    jugador.invencibilidad_tiempo = 0
    -- temporizador para invencibilidad
    return jugador
end

function Jugador:Morir()
    -- aquれと puedes agregar animaciones o efectos de muerte
    print("el jugador ha muerto!")
    jugador.muerto = true
    estado_juego = "fin"
    -- cambiar el estado del juego a "fin"
end

function Jugador:activar_invencibilidad()
    self.invencible = true
    self.invencibilidad_tiempo = 2
    -- 2 segundos de invencibilidad, puedes ajustar esto
end

function Jugador:actualizar_invencibilidad()
    if self.invencible then
        self.invencibilidad_tiempo -= 1 / 30 -- reduce el tiempo cada frame (a 30 fps)
        if self.invencibilidad_tiempo <= 0 then
            self.invencible = false -- desactivar la invencibilidad cuando se acabe el tiempo
        end
    end
end

function Jugador:activar_velocidad_ataque()
    tiempo_entre_disparos = 0.15
    tiempo_ataque_reducido = true
    tiempo_ataque_fin = time() + 15
end

function Jugador:actualizar_tiempo_ataque()
    if tiempo_ataque_reducido and time() > tiempo_ataque_fin then
        tiempo_entre_disparos = 0.3
        tiempo_ataque_reducido = false
    end
end

-- ENEMIGO
Enemigo = setmetatable({}, Personaje)
Enemigo.__index = Enemigo

function Enemigo:Crear()
    local x_aleatorio, y_aleatorio
    local intentos = 0
    local max_intentos = 100
    -- lれとmite de intentos para evitar bucles infinitos

    repeat
        x_aleatorio = flr(rnd(MUNDO_ANCHO - 2)) + 2
        y_aleatorio = flr(rnd(MUNDO_ALTO - 3)) + 2
        intentos += 1

        local atrapado_horizontal = es_no_transitable(x_aleatorio - 1, y_aleatorio)
                and es_no_transitable(x_aleatorio + 1, y_aleatorio)
        -- generar posiciれはn aleatoria dentro del rango vれくlido del mapa

        -- verificar que la posiciれはn no estれた atrapada entre dos bloques no transitables

        -- verificar que la posiciれはn sea transitable y no haya colisiones con otros enemigos
    until not es_no_transitable(x_aleatorio, y_aleatorio)
            and not atrapado_horizontal
            and not ColisionConEnemigos({ x = x_aleatorio, y = y_aleatorio, ancho = self.ancho, alto = self.alto })
            and intentos < max_intentos

    if intentos == max_intentos then
        -- si no se encuentra una posiciれはn vれくlida, cancelar la generaciれはn
        return nil
    end

    -- inicializar propiedades ancho y alto si no estれくn definidas
    self.ancho = self.ancho or 8
    self.alto = self.alto or 8

    -- crear el enemigo en la posiciれはn vれくlida
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
        if not jugador.muerto and not jugador.invencible then
            -- verificar que no estれた muerto ni invencible
            vidas -= 1
            jugador:activar_invencibilidad() -- activar invencibilidad temporal
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
        local x, y = self.x, self.y

        -- determinar si cae un recolectable y de quれた tipo
        local probabilidad = rnd(1) -- nれむmero aleatorio entre 0 y 1
        if probabilidad < 0.3 then
            crear_recolectable(x, y, 1) -- tipo 1: curaciれはn
        elseif probabilidad < 0.45 then
            crear_recolectable(x, y, 2) -- tipo 2: aumento de velocidad de ataque
        end

        self:Destruir()
    end
end

function Enemigo:Destruir()
    del(enemigos, self)
end

-- enemigo 2
enemigo_tipo2 = setmetatable({}, Personaje)
enemigo_tipo2.__index = enemigo_tipo2

function enemigo_tipo2:crear()
    local max_intentos = 100
    local intentos = 0
    local ancho_tiles = 2
    -- tamaれねo del enemigo en tiles (2x2)
    local alto_tiles = 2
    local x_aleatorio, y_aleatorio

    repeat
        x_aleatorio = flr(rnd(MUNDO_ANCHO - ancho_tiles)) + 1
        y_aleatorio = flr(rnd(MUNDO_ALTO - alto_tiles)) + 1
        intentos += 1
    until self:es_posicion_valida(x_aleatorio, y_aleatorio, ancho_tiles, alto_tiles)
            and not ColisionConEnemigos({ x = x_aleatorio, y = y_aleatorio, ancho = ancho_tiles * TILE_SIZE, alto = alto_tiles * TILE_SIZE })
            and intentos < max_intentos

    if intentos == max_intentos then
        return nil -- no se pudo generar un enemigo vれくlido
    end

    -- inicializaciれはn del enemigo
    self.ancho = ancho_tiles * TILE_SIZE
    self.alto = alto_tiles * TILE_SIZE
    local enemigo = setmetatable(Personaje.Crear(self, x_aleatorio * TILE_SIZE, y_aleatorio * TILE_SIZE, 100), enemigo_tipo2)
    enemigo.direccion = -1
    enemigo.velocidad = 0.75
    enemigo.sprite = 6
    enemigo.vida = 100
    enemigo.rango_det = 32
    return enemigo
end

function enemigo_tipo2:es_posicion_valida(x, y, ancho_tiles, alto_tiles)
    for ty = y, y + alto_tiles - 1 do
        for tx = x, x + ancho_tiles - 1 do
            if mapa[ty] == nil or mapa[ty][tx] == nil or mapa[ty][tx] == 32 then
                return false -- espacio ocupado o fuera del mapa
            end
        end
    end

    -- verificar que no estれた rodeado lateralmente por bloques intranzitables
    local izquierda_bloqueada = mapa[y][x - 1] == 32 and mapa[y + alto_tiles - 1][x - 1] == 32
    local derecha_bloqueada = mapa[y][x + ancho_tiles] == 32 and mapa[y + alto_tiles - 1][x + ancho_tiles] == 32

    return not (izquierda_bloqueada and derecha_bloqueada)
end

function enemigo_tipo2:Movimiento()
    local dx = jugador.x - self.x
    local dy = jugador.y - self.y
    local distancia = sqrt(dx ^ 2 + dy ^ 2)

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
        if not jugador.muerto and not jugador.invencible then
            -- verificar que no estれた muerto ni invencible
            vidas -= 1
            jugador:activar_invencibilidad() -- activar invencibilidad temporal
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
        local x, y = self.x, self.y

        -- determinar si cae un recolectable y de quれた tipo
        local probabilidad = rnd(1) -- nれむmero aleatorio entre 0 y 1
        if probabilidad < 0.3 then
            crear_recolectable(x, y, 1) -- tipo 1: curaciれはn
        elseif probabilidad < 0.45 then
            crear_recolectable(x, y, 2) -- tipo 2: aumento de velocidad de ataque
        end

        self:Destruir()
    end
end

function enemigo_tipo2:Destruir()
    del(enemigos, self)
end

-- FLECHA
Flecha = setmetatable({}, Entidad)
Flecha.__index = Flecha

function Flecha:Crear(x, y, velocidad_x, velocidad_y, direccion)
    local flecha = setmetatable(Entidad.Crear(self, x, y), Flecha)
    flecha.velocidad_x = velocidad_x or 0
    flecha.velocidad_y = velocidad_y or 0
    flecha.ancho = 4
    flecha.direccion = direccion
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

--recolectables

function crear_recolectable(x, y, tipo)
    if (tipo == 1) then
        local recolectable = {
            x = x,
            y = y,
            tipo = tipo,
            sprite = 65
        }
        add(recolectables, recolectable)
    end
    if (tipo == 2) then
        local recolectable = {
            x = x,
            y = y,
            tipo = tipo,
            sprite = 64
        }
        add(recolectables, recolectable)
    end
end

-- MUNDO
Mundo = {}
Mundo.__index = Mundo

MUNDO_ANCHO = 16
MUNDO_ALTO = 16
TILE_SIZE = 8

function Mundo:Generar()
    mapa = {}
    no_transitables = {}
    -- tabla para guardar las posiciones no transitables

    for y = 1, MUNDO_ALTO do
        mapa[y] = {}
        for x = 1, MUNDO_ANCHO do
            -- primera fila (y == 1) serれく negra (vacれとa o sin elementos visibles)
            if y == 1 then
                mapa[y][x] = 0 -- usar un valor que corresponda al color negro o vacれとo
                -- segunda fila (y == 2) tendrれく los れくrboles (u objetos similares)
            elseif y == 2 then
                -- aquれと generamos una hilera de れくrboles
                if x == 1 or x == MUNDO_ANCHO then
                    mapa[y][x] = 32 -- un れくrbol en los bordes
                else
                    mapa[y][x] = 32 -- れ▒rboles en los otros espacios
                end
                add(no_transitables, { x = x, y = y }) -- marcar las posiciones de los れくrboles como no transitables
                -- para las demれくs filas
            elseif x == 1 or x == MUNDO_ANCHO or y == MUNDO_ALTO then
                mapa[y][x] = 32 -- paredes
                add(no_transitables, { x = x, y = y })
            else
                if rnd(1) < 0.1 then
                    mapa[y][x] = 32 -- obstれくculo
                    add(no_transitables, { x = x, y = y })
                else
                    mapa[y][x] = 16 -- piso transitable
                end
            end
        end
    end
end

function Mundo:Dibujar()
    for y = 1, MUNDO_ALTO do
        for x = 1, MUNDO_ANCHO do
            -- para la primera fila (negra), no dibujamos nada, lo dejamos vacれとo
            if mapa[y][x] ~= 0 then
                spr(mapa[y][x], (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
            end
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
function es_no_transitable(x, y)
    for obstaculo in all(no_transitables) do
        if obstaculo.x == x and obstaculo.y == y then
            return true -- la posiciれはn es no transitable
        end
    end
    return false
    -- la posiciれはn es transitable
end

function ColisionConTerrenoCompleto(x, y, ancho, alto)
    local tile_x1 = flr(x / TILE_SIZE) + 1
    local tile_y1 = flr(y / TILE_SIZE) + 1
    local tile_x2 = flr((x + ancho - 1) / TILE_SIZE) + 1
    local tile_y2 = flr((y + alto - 1) / TILE_SIZE) + 1
    return (mapa[tile_y1] and (mapa[tile_y1][tile_x1] == 32 or mapa[tile_y1][tile_x2] == 32))
            or (mapa[tile_y2] and (mapa[tile_y2][tile_x1] == 32 or mapa[tile_y2][tile_x2] == 32))
end

function colisionconrecolectables()
    for recolectable in all(recolectables) do
        if abs(jugador.x - recolectable.x) < 8 and abs(jugador.y - recolectable.y) < 8 then
            if recolectable.tipo == 1 then
                vidas += 1
                curas_recogidas += 1 -- incrementar el contador de curas
                tiempo_mostrar_cura = 60 * 2 -- mostrar el +1 durante 2 segundos (60 fps)
            end
            if recolectable.tipo == 2 then
                jugador:activar_velocidad_ataque()
                aumento_recodigos += 1
                tiempo_mostrar_aumento = 60 * 15
            end
            del(recolectables, recolectable)
        end
    end
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
        local puerta_x1 = flr(MUNDO_ANCHO / 2) - 1
        local puerta_x2 = puerta_x1 + 1
        local puerta_y = 2
        mapa[puerta_y][puerta_x1] = 16
        mapa[puerta_y][puerta_x2] = 16
    end
end

function VerificarVictoria()
    if puerta_abierta then
        local puerta_x = (flr(MUNDO_ANCHO / 2) - 1) * TILE_SIZE
        local puerta_y = 2

        if jugador.x >= puerta_x and jugador.x <= puerta_x + TILE_SIZE and jugador.y <= puerta_y + TILE_SIZE then
            estado_juego = "victoria"
            mostrar_mensaje_victoria = true
        end
    end
end

function avanzar_nivel()
    nivel_actual += 1
    Mundo:Generar()
    iniciar_juego(false)
    estado_juego = "jugando"
end

-- CICLO DEL JUEGO
function _init()
    
    Mundo:Generar()
    iniciar_juego(true)
end

function _update()
    if not stat(57) then
        music(0)
    end
        if jugador.muerto then
        if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego(true)
        end
    end
    if estado_juego == "inicio" then
        if btnp(4) or btnp(5) then
            estado_juego = "jugando"
            iniciar_juego(true)
        end
    elseif estado_juego == "jugando" then
        if btn(0) then jugador:Movimiento(-1, 0) end
        if btn(1) then jugador:Movimiento(1, 0) end
        if btn(2) then jugador:Movimiento(0, -1) end
        if btn(3) then jugador:Movimiento(0, 1) end

        jugador:actualizar_invencibilidad()

        -- verificar si ha pasado el tiempo suficiente para disparar
        tiempo_ultimo_disparo += 1 / 30 -- contamos el tiempo (30 fps)

        if btnp(4) and tiempo_ultimo_disparo >= tiempo_entre_disparos then
            sfx(0)
            -- lれはgica para disparar
            if btn(0) then
                -- izquierda
                add(flechas, Flecha:Crear(jugador.x, jugador.y, -3, 0, 0)) -- dispara a la izquierda
            elseif btn(1) then
                -- derecha
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 3, 0, 1)) -- dispara a la derecha
            elseif btn(2) then
                -- arriba
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 0, -3, 2)) -- dispara arriba
            elseif btn(3) then
                -- abajo
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 0, 3, 3)) -- dispara abajo
            else
                add(flechas, Flecha:Crear(jugador.x, jugador.y, 0, -3, 2)) -- por defecto dispara arriba
            end
            tiempo_ultimo_disparo = 0
        end

        -- actualizar flechas y enemigos
        for flecha in all(flechas) do
            flecha:Comportamiento()
        end
        for enemigo in all(enemigos) do
            enemigo:Movimiento()
            enemigo:ColisionConJugador() -- agrega esta linea
        end

        colisionconrecolectables()
        Jugador:actualizar_tiempo_ataque()

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
            iniciar_juego(true)
            vidas = 3
        end
    elseif estado_juego == "victoria" then
        if mostrar_mensaje_victoria then
            print("るくfelicitaciones! nivel completado.")
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
        for i = 1, vidas do
            spr(80, 8 * i - 8, 0)
        end
        local x_offset = 8 * vidas
        if tiempo_mostrar_cura > 0 then
            print("+1", 8 * vidas, 0, 8) -- cambia la posiciれはn segれむn donde quieras mostrarlo
            tiempo_mostrar_cura -= 1 -- disminuir el temporizador en cada cuadro
            x_offset += 8
        end
        if tiempo_mostrar_aumento > 0 then
            spr(51, 8 * vidas, 0)
            print(tiempo_mostrar_aumento, 0, 0, 7)
            tiempo_mostrar_aumento -= 1
            x_offset += 8
        end
        print("enemigos " .. #enemigos, 50, 0, 7)
        print("nivel: " .. nivel_actual, 95, 0, 7)
        Mundo:Dibujar()
        if jugador.invencible then
            -- alternar visibilidad del sprite para crear el parpadeo
            if flr(time() / 0.2) % 2 == 0 then
                -- parpadeo cada 0.2 segundos
                spr(1, jugador.x, jugador.y)
            end
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
            if (flecha.direccion == 0) then
                --izq
                spr(49, flecha.x, flecha.y)
            elseif (flecha.direccion == 1) then
                --derecha
                spr(49, flecha.x, flecha.y, 1, 1, true, true)
            elseif (flecha.direccion == 2) then
                --arriba
                spr(48, flecha.x, flecha.y)
            elseif (flecha.direccion == 3) then
                --abajo
                spr(48, flecha.x, flecha.y, 1, 1, false, true)
            end
        end

        draw_recolectables()
    elseif estado_juego == "fin" then
        print("has muerto!", 50, 60, 8)
        print("pulsa x para reiniciar", 20, 80, 7)
    elseif estado_juego == "victoria" then
        print("るくFelicidades, ganaste!", 20, 50, 11)
        print("toca algun boton para ", 20, 80, 7)
        print("continuar al", 20, 90, 7)
        print("siguiente nivel", 20, 100, 7)
    end
end

function draw_recolectables()
    for recolectable in all(recolectables) do
        local flotacion = sin((time() * 2) + recolectable.x) * 1.5
        spr(recolectable.sprite, recolectable.x, recolectable.y + flotacion)
    end
end

__gfx__
00000000009999000000000000000000000000000000330000880880000000000000000000000000000000000000000000000000000000000000000000000000
0000000009aaaa900000000000000000000000000003300000888880003333000000000000000000000000000000000000000000000000000000000000000000
007007009a5aa5a900000000000000000000000000088007088a8a88033883300000000000000000000000000000000000000000000000000000000000000000
000770009aaaaaa90000000000000000000000000088880d08888888338858330000000000000000000000000000000000000000000000000000000000000000
000770009a5aa5a90000000000000000000000000088880d08844488385888830000000000000000000000000000000000000000000000000000000000000000
007007009aa55aa90000000000000000000000000008885d08448448338858330000000000000000000000000000000000000000000000000000000000000000
0000000009aaaa900000000000000000000000000008880d00888880033883300000000000000000000000000000000000000000000000000000000000000000
00000000009999000000000000000000000000000088800d00880880003333000000000000000000000000000000000000000000000000000000000000000000
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
000000000000000000000000000000b0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000000000000000000000bbb660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000555000000000000000000000000b0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000005000600000000006000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000055444400005500004444550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000005000600000000006000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010300000d65030d05056301090506650103050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01160010183101c3101f3101c31024310283102b31034310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600080c020130200c0201302000020070200002007020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600100000000000000000000000000000000000000000183101c3101f3101c31024310283102b3103431000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020000018a5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01020344

