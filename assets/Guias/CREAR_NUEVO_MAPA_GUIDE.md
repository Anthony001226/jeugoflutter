# 🗺️ Guía Completa: Crear Nuevo Mapa con Pasillo y Barrera

Esta guía te enseña a:
1. Crear un nuevo mapa (ej: `granja.tmx`) 
2. Crear un pasillo/entrada en `dungeon.tmx` que conecte al nuevo mapa
3. Configurar un portal para transportarte entre mapas
4. (Opcional) Añadir una barrera condicional para bloquear el acceso

---

## 📋 Parte 1: Crear el Nuevo Mapa

### 1.1 Crear archivo de mapa

1. Abre **Tiled**
2. Ve a **Archivo** → **Nuevo** → **Nuevo Mapa...**
3. Configura los parámetros:
   - **Orientación**: Isometric
   - **Tamaño de tile**: 
     - Ancho: `32`
     - Alto: `16`
   - **Tamaño del mapa**:
     - Ancho: `30` tiles (o el que quieras)
     - Alto: `30` tiles
   - **Tipo de capa de tiles**: Finite

4. Click en **OK**

### 1.2 Guardar el mapa

1. **Archivo** → **Guardar Como...**
2. Navega a: `assets/tiles/`
3. Nombre: `granja.tmx` (o el nombre que prefieras)
4. Click en **Guardar**

### 1.3 Añadir tilesets

1. En el panel **Tilesets**, click en **Añadir Tileset**
2. Selecciona los mismos tilesets que usas en `dungeon.tmx`:
   - `arboles.tsx`
   - `interior.tsx`
   - `dungeon_tileset.tsx`
   - Etc.

### 1.4 Crear capas básicas

Crea las siguientes capas (en este orden, de abajo hacia arriba):

1. **Ground** (Capa de Tiles)
   - El suelo base
   - Dibuja el terreno de tu mapa

2. **Details** (Capa de Tiles)
   - Detalles como flores, rocas, etc.

3. **Collision** (Capa de Tiles)
   - Tiles que bloquean el paso
   - Usa tiles invisibles o tiles de colisión
   - **Importante**: Marca la capa como invisible si quieres

4. **SpawnZones** (Capa de Objetos)
   - Define zonas de enemigos (opcional)

5. **Portals** (Capa de Objetos)
   - **MUY IMPORTANTE** para volver a dungeon.tmx

### 1.5 Configurar punto de retorno (Portal de vuelta)

1. Selecciona la capa **Portals**
2. Dibuja un rectángulo pequeño (2x2 tiles) cerca de la "entrada" de tu mapa
3. Selecciona el rectángulo y añade propiedades:
   - `name` (String): `"to_dungeon"`
   - `targetMap` (String): `"dungeon.tmx"`
   - `targetX` (int): Coordenada X en dungeon donde quieres aparecer
   - `targetY` (int): Coordenada Y en dungeon
   - `gridX` (int): Posición X del portal en ESTE mapa
   - `gridY` (int): Posición Y del portal en ESTE mapa

4. **Guarda el mapa** (Ctrl+S)

---

## 📋 Parte 2: Crear Pasillo en dungeon.tmx

### 2.1 Abrir dungeon.tmx

1. Abre `assets/tiles/dungeon.tmx` en Tiled

### 2.2 Dibujar el pasillo

1. Selecciona la capa **Ground**
2. Elige el tileset que quieras usar
3. Dibuja un pasillo/camino que conduzca a la nueva zona
   - Puede ser un camino de piedra
   - Puede ser una puerta en la pared
   - Puede ser una escalera

**Ejemplo**: Si el mapa principal es un dungeon y quieres salir a una granja, dibuja un camino que vaya hacia "afuera".

### 2.3 Añadir detalles visuales

1. Selecciona la capa **Details**
2. Añade decoración al pasillo:
   - Antorchas en las paredes
   - Señales
   - Puertas
   - Lo que quieras para que se vea bonito

---

## 📋 Parte 3: Configurar Portal de Salida

### 3.1 Crear portal en dungeon.tmx

1. Selecciona la capa **Portals** en dungeon.tmx
2. Usa la herramienta **Insertar Rectángulo**
3. Dibuja un rectángulo al **final** del pasillo (donde el jugador entrará)

### 3.2 Configurar propiedades del portal

Click en el rectángulo y añade estas propiedades:

- **`name`** (String): `"to_granja"` (o el nombre que quieras)
- **`targetMap`** (String): `"granja.tmx"` (el archivo que creaste)
- **`targetX`** (int): `15` (coordenada X inicial en granja)
- **`targetY`** (int): `15` (coordenada Y inicial en granja)
- **`gridX`** (int): La coordenada X del portal en dungeon (ej: `25`)
- **`gridY`** (int): La coordenada Y del portal en dungeon (ej: `30`)

### 3.3 Verificar coordenadas

Para saber las coordenadas grid:
1. Pasa el mouse sobre el tile del portal
2. Mira en la parte inferior de Tiled
3. Verás algo como `(25, 30)` - esos son gridX y gridY

**Guarda dungeon.tmx** (Ctrl+S)

---

## 📋 Parte 4: (OPCIONAL) Añadir Barrera Condicional

Si quieres que solo jugadores de cierto nivel o que hayan derrotado un boss puedan acceder:

### 4.1 Crear capa de barreras (si no existe)

1. En **dungeon.tmx**, crea una capa **ConditionalBarriers** (Capa de Objetos)

### 4.2 Dibujar barrera

1. Selecciona la capa **ConditionalBarriers**
2. Dibuja un rectángulo **ANTES** del portal
   - Debe bloquear el pasillo
   - Que cubra 1-2 tiles de ancho

### 4.3 Configurar barrera

Añade propiedades al rectángulo:

```
id: "granja_entrance"
requiredLevel: 15
requiredBoss: "first_boss"
blockedMessage: "Necesitas ser nivel 15 y derrotar al Guardian del Panteón"
unlockedMessage: "¡El camino a la Granja está abierto!"
```

### 4.4 Orden correcto

El orden debería ser:
```
[Jugador] → [Barrera] → [Portal] → [Nuevo Mapa]
```

Cuando el jugador cumple requisitos:
1. Pasa la barrera
2. Pisa el portal
3. Se transporta al nuevo mapa

---

## 📋 Parte 5: Verificar el Sistema

### 5.1 Archivos que debes tener

- ✅ `assets/tiles/dungeon.tmx` (modificado - tiene portal y barrera)
- ✅ `assets/tiles/granja.tmx` (nuevo - tu nuevo mapa)
- ✅ Ambos mapas tienen capa **Portals**

### 5.2 Cargar el nuevo mapa en el código

El código ya soporta múltiples mapas, solo necesitas que el archivo `.tmx` exista en `assets/tiles/`.

### 5.3 Probar en el juego

1. **Corre el juego**
2. **Ve al pasillo** que creaste en dungeon.tmx
3. **Intenta pasar**:
   - Si hay barrera y no cumples requisitos → Bloqueado (mensaje en consola)
   - Si cumples requisitos o no hay barrera → Llegas al portal
4. **Pisa el portal** → Deberías ver mensaje: `🚪 Transitioning to granja.tmx...`
5. **Apareces en el nuevo mapa**
6. **Ve al portal de retorno** → Deberías volver a dungeon.tmx

---

## 🎨 Diagrama del Sistema

```
┌─────────────────────────────────────┐
│        DUNGEON.TMX (Mapa 1)        │
│                                     │
│    [Jugador]                        │
│        ↓                            │
│    [Pasillo]                        │
│        ↓                            │
│    [Barrera Condicional] ← Opcional │
│    (Nivel 15 + Boss)                │
│        ↓                            │
│    [Portal "to_granja"]             │
│    (gridX: 25, gridY: 30)           │
└──────────────┬──────────────────────┘
               │
               │ Transporta a...
               ↓
┌─────────────────────────────────────┐
│         GRANJA.TMX (Mapa 2)        │
│                                     │
│    [Jugador aparece aquí]           │
│    (targetX: 15, targetY: 15)       │
│        ↓                            │
│    [Explora la granja]              │
│        ↓                            │
│    [Portal "to_dungeon"]            │
│    (cerca de la entrada)            │
└──────────────┬──────────────────────┘
               │
               │ Regresa a...
               ↓
          DUNGEON.TMX
```

---

## 🛠️ Ejemplo Paso a Paso Completo

### Escenario: Crear una Granja accesible desde el Dungeon

#### En dungeon.tmx:

1. **Dibuja camino** hacia el norte (tiles de hierba)
2. **Crea portal** al final del camino:
   ```
   name: "to_granja"
   targetMap: "granja.tmx"
   targetX: 15
   targetY: 15
   gridX: 20
   gridY: 5
   ```
3. **Crea barrera** antes del portal:
   ```
   id: "granja_gate"
   requiredLevel: 10
   blockedMessage: "La granja solo está abierta para aventureros experimentados (Nivel 10+)"
   ```

#### En granja.tmx:

1. **Dibuja mapa** con césped, árboles, granero
2. **Crea portal de retorno** cerca de donde el jugador aparece:
   ```
   name: "to_dungeon"
   targetMap: "dungeon.tmx"
   targetX: 20
   targetY: 5
   gridX: 15
   gridY: 15
   ```
3. **Configura zonas** (opcional):
   ```
   SpawnZone: "Granja"
   enemyTypes: "slime"
   encounterChance: 0.01
   dangerLevel: "safe"
   ```

---

## ❓ Troubleshooting

### "El portal no me transporta"
- ✅ Verifica que `gridX` y `gridY` sean las coordenadas correctas del portal
- ✅ Verifica que `targetMap` sea el nombre exacto del archivo (ej: `"granja.tmx"`)
- ✅ Verifica que el archivo `.tmx` esté en `assets/tiles/`
- ✅ Mira la consola para ver mensajes de error

### "Aparezco en un lugar raro del nuevo mapa"
- ✅ Ajusta `targetX` y `targetY` a las coordenadas deseadas
- ✅ Recuerda que las coordenadas son en grid, no en píxeles

### "No puedo volver al mapa original"
- ✅ Asegúrate de haber creado el portal de retorno en el nuevo mapa
- ✅ Verifica que `targetMap` apunte a `"dungeon.tmx"`

### "La barrera no se carga"
- ✅ La capa debe llamarse exactamente `ConditionalBarriers`
- ✅ Guarda el mapa después de crear la barrera
- ✅ Mira la consola al cargar el mapa: `✅ Loaded X conditional barriers`

---

## 🚀 Comandos de Debug Útiles

En la consola del juego (F12), puedes usar:

```dart
// Ver bosses derrotados
game.player.stats.defeatedBosses

// Marcar boss como derrotado
game.player.stats.defeatBoss("first_boss")

// Subir nivel
game.player.stats.level.value = 15

// Teletransportarse a un mapa
game.transitionToMap("granja.tmx", Vector2(15, 15))
```

---

## ✅ Checklist Final

Antes de probar, verifica que tengas:

- [ ] Nuevo mapa creado (`granja.tmx`)
- [ ] Nuevo mapa tiene capa **Portals**
- [ ] Portal de retorno configurado en nuevo mapa
- [ ] Pasillo dibujado en `dungeon.tmx`
- [ ] Portal de salida en `dungeon.tmx`
- [ ] (Opcional) Barrera condicional configurada
- [ ] Ambos mapas guardados
- [ ] Coordenadas de portales verificadas

---

¡Listo! Ahora tienes un sistema completo de mapas conectados con portales y barreras opcionales 🎮
