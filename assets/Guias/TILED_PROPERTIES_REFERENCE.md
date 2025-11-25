# 📖 Referencia Completa: Propiedades de Tiled

Esta guía lista **TODAS** las propiedades disponibles para cada tipo de objeto en Tiled.

---

## 🗺️ SPAWN ZONES (Zonas de Enemigos)

### Capa: `SpawnZones` (Capa de Objetos)
### Objeto: Rectángulo

### Propiedades Disponibles:

| Propiedad | Tipo | Requerido | Descripción | Ejemplo |
|-----------|------|-----------|-------------|---------|
| `name` | String | ✅ Sí | Nombre de la zona | `"Bosque Oscuro"` |
| `enemyTypes` | String | ✅ Sí | Tipos de enemigos separados por comas | `"slime,goblin"` |
| `dangerLevel` | String | ⚠️ Recomendado | Nivel de peligro | `"safe"`, `"low"`, `"medium"`, `"high"` |
| `encounterChance` | float | ⚠️ Recomendado | Probabilidad de encuentro por paso | `0.02` (2%) |
| `minLevel` | int | ❌ Opcional | Nivel mínimo del jugador | `1` |
| `maxLevel` | int | ❌ Opcional | Nivel máximo del jugador | `99` |
| `maxRarity` | String | ❌ Opcional | Raridad máxima de drops | `"common"`, `"uncommon"`, `"rare"`, `"epic"`, `"legendary"` |

### Ejemplo Completo:

```
nombre: "Cueva Profunda"
enemyTypes: "bat,skeleton"
dangerLevel: "high"
encounterChance: 0.05
minLevel: 10
maxLevel: 99
maxRarity: "rare"
```

### Valores Válidos:

#### `enemyTypes`:
- `"slime"` - Slime verde
- `"goblin"` - Goblin
- `"bat"` - Murciélago
- `"skeleton"` - Esqueleto
- Combinaciones: `"slime,goblin"`, `"bat,skeleton,goblin"`

#### `dangerLevel`:
- `"safe"` - Sin encuentros aleatorios
- `"low"` - Baja probabilidad, enemigos débiles
- `"medium"` - Probabilidad media, enemigos normales
- `"high"` - Alta probabilidad, enemigos fuertes

#### `encounterChance`:
- `0.00` = 0% (nunca)
- `0.01` = 1% por paso
- `0.02` = 2% por paso (recomendado para zonas normales)
- `0.05` = 5% por paso (zonas peligrosas)
- `0.10` = 10% por paso (muy peligroso)

---

## 🌀 PORTALS (Portales entre Mapas)

### Capa: `Portals` (Capa de Objetos)
### Objeto: Rectángulo o Punto

### Propiedades Disponibles:

| Propiedad | Tipo | Requerido | Descripción | Ejemplo |
|-----------|------|-----------|-------------|---------|
| `name` | String | ✅ Sí | Nombre del portal | `"to_granja"` |
| `targetMap` | String | ✅ Sí | Archivo del mapa destino | `"granja.tmx"` |
| `targetX` | int | ✅ Sí | Coordenada X en mapa destino | `15` |
| `targetY` | int | ✅ Sí | Coordenada Y en mapa destino | `20` |
| `gridX` | int | ✅ Sí | Coordenada X en mapa actual | `25` |
| `gridY` | int | ✅ Sí | Coordenada Y en mapa actual | `30` |

### Ejemplo Completo:

```
name: "to_granja"
targetMap: "granja.tmx"
targetX: 15
targetY: 20
gridX: 25
gridY: 30
```

### Notas Importantes:

- **`gridX` y `gridY`**: Son las coordenadas EN ESTE MAPA donde está el portal
- **`targetX` y `targetY`**: Son las coordenadas EN EL MAPA DESTINO donde aparecerá el jugador
- **`targetMap`**: DEBE incluir la extensión `.tmx`
- El archivo `.tmx` DEBE estar en `assets/tiles/`

### Cómo Obtener Coordenadas:

1. Pasa el mouse sobre el tile deseado en Tiled
2. Mira la esquina inferior izquierda
3. Verás algo como `(25, 30)` - esos son los valores grid

---

## 🚪 CONDITIONAL BARRIERS (Barreras Condicionales)

### Capa: `ConditionalBarriers` (Capa de Objetos)
### Objeto: Rectángulo

### Propiedades Disponibles:

| Propiedad | Tipo | Requerido | Descripción | Ejemplo |
|-----------|------|-----------|-------------|---------|
| `id` | String | ⚠️ Recomendado | Identificador único | `"granja_gate"` |
| `requiredLevel` | int | ❌ Opcional | Nivel mínimo requerido | `15` |
| `requiredBoss` | String | ❌ Opcional | ID del boss que debe estar derrotado | `"first_boss"` |
| `requiredQuest` | String | ❌ Opcional | ID de quest requerida (futuro) | `"quest_001"` |
| `blockedMessage` | String | ⚠️ Recomendado | Mensaje cuando está bloqueado | `"Necesitas nivel 15"` |
| `unlockedMessage` | String | ❌ Opcional | Mensaje cuando se desbloquea | `"¡Camino abierto!"` |

### Ejemplo Completo:

```
id: "dungeon_entrance"
requiredLevel: 10
requiredBoss: "forest_guardian"
requiredQuest: "none"
blockedMessage: "Solo los que han derrotado al Guardián del Bosque pueden entrar aquí (Nivel 10+)"
unlockedMessage: "El sello mágico se rompe. El dungeon está abierto."
```

### Valores Válidos:

#### `requiredLevel`:
- `0` = Sin requisito de nivel
- `1-99` = Nivel específico requerido

#### `requiredBoss`:
- `"none"` = Sin requisito de boss
- `"first_boss"` = Primer jefe del juego
- `"second_boss"` = Segundo jefe
- `"skeleton_king"` = Rey Esqueleto
- Cualquier ID personalizado que definas

#### `requiredQuest`:
- `"none"` = Sin requisito de quest
- Cualquier ID de quest (para futuro)

### Notas Importantes:

- **Al menos UNA condición** debe estar activa (nivel, boss, o quest)
- Puedes combinar múltiples requisitos
- Una vez desbloqueada, la barrera permanece abierta
- Si no cumples requisitos, el movimiento se bloquea

---

## 💰 CHESTS (Cofres) - Sistema Existente

### Capa: `Chests` (Capa de Objetos)
### Objeto: Punto o Rectángulo

### Propiedades Disponibles:

| Propiedad | Tipo | Requerido | Descripción | Ejemplo |
|-----------|------|-----------|-------------|---------|
| `item` | String | ✅ Sí | ID del item que contiene | `"potion"` |
| `gridX` | int | ✅ Sí | Coordenada X del cofre | `10` |
| `gridY` | int | ✅ Sí | Coordenada Y del cofre | `15` |

### Ejemplo Completo:

```
item: "potion"
gridX: 10
gridY: 15
```

### Items Disponibles:

- `"potion"` - Poción de vida
- `"ether"` - Éter (restaura MP)
- `"rustySword"` - Espada oxidada
- `"goblinScimitar"` - Cimitarra de goblin
- `"skeletonSword"` - Espada de esqueleto
- `"leatherTunic"` - Túnica de cuero
- Cualquier item definido en `ItemDatabase`

---

## 🗺️ PLANTILLA: Nuevo Mapa Completo

### Archivo: `nuevo_mapa.tmx`

#### Configuración del Mapa:
```
Orientación: Isometric
Tile Width: 32
Tile Height: 16
Map Width: 30 tiles
Map Height: 30 tiles
```

#### Capas Necesarias (en orden):

1. **Ground** (Tile Layer)
   - Suelo base

2. **Details** (Tile Layer)
   - Detalles visuales

3. **Collision** (Tile Layer)
   - Tiles que bloquean

4. **SpawnZones** (Object Layer)
   - Zonas de enemigos

5. **Portals** (Object Layer)
   - Portales a otros mapas

6. **ConditionalBarriers** (Object Layer) - Opcional
   - Barreras condicionales

7. **Chests** (Object Layer) - Opcional
   - Cofres con items

---

## 📋 EJEMPLO COMPLETO: Mapa "Granja"

### SpawnZone 1:
```
name: "Campos Seguros"
enemyTypes: "slime"
dangerLevel: "safe"
encounterChance: 0.00
minLevel: 1
maxLevel: 99
```

### SpawnZone 2:
```
name: "Granero Abandonado"
enemyTypes: "bat,goblin"
dangerLevel: "low"
encounterChance: 0.02
minLevel: 5
maxLevel: 99
maxRarity: "uncommon"
```

### Portal (Retorno a Dungeon):
```
name: "to_dungeon"
targetMap: "dungeon.tmx"
targetX: 20
targetY: 10
gridX: 15
gridY: 15
```

### Cofre:
```
item: "potion"
gridX: 12
gridY: 18
```

---

## 🎨 CONVENCIONES DE NOMBRES

### Para IDs de Bosses:
- `first_boss` - Primer jefe
- `second_boss` - Segundo jefe
- `{location}_{boss_name}` - Ej: `forest_guardian`, `cave_troll`

### Para IDs de Barreras:
- `{location}_entrance` - Ej: `granja_entrance`, `cave_entrance`
- `{location}_gate` - Ej: `dungeon_gate`

### Para Nombres de Portales:
- `to_{destination}` - Ej: `to_granja`, `to_dungeon`, `to_cave`
- `from_{origin}` - Ej: `from_dungeon`, `from_granja`

### Para Nombres de Zonas:
- Descriptivos y específicos
- Ej: `"Bosque Oscuro"`, `"Pradera Tranquila"`, `"Cueva Profunda"`

---

## ⚠️ ERRORES COMUNES

### ❌ Error: Portal no funciona
**Causa**: `targetMap` sin extensión
**Solución**: Usa `"granja.tmx"`, no `"granja"`

### ❌ Error: Barrera no se carga
**Causa**: Capa mal nombrada
**Solución**: Debe ser `ConditionalBarriers`, exacto

### ❌ Error: Enemigos no aparecen
**Causa**: `enemyTypes` vacío o `dangerLevel: "safe"`
**Solución**: Define enemigos y cambia danger level

### ❌ Error: Jugador aparece fuera del mapa
**Causa**: `targetX` o `targetY` incorrectos
**Solución**: Verifica las coordenadas sean válidas

---

## 🔧 COMANDOS DE DEBUG

Para probar sin editar el mapa:

```dart
// Marcar boss como derrotado
game.player.stats.defeatBoss("first_boss")

// Cambiar nivel
game.player.stats.level.value = 15

// Ver bosses derrotados
print(game.player.stats.defeatedBosses)

// Teletransportarse
game.transitionToMap("granja.tmx", Vector2(15, 15))

// Ver barreras cargadas
print(game.conditionalBarriers.length)

// Ver portales cargados
print(game.portals.length)
```

---

## ✅ CHECKLIST DE VERIFICACIÓN

Antes de probar un mapa nuevo:

**Archivo y Capas:**
- [ ] Mapa guardado en `assets/tiles/`
- [ ] Orientación: Isometric
- [ ] Tile size: 32x16
- [ ] Capa `Collision` existe
- [ ] Capa `Portals` existe

**Portales:**
- [ ] Todos los portales tienen `targetMap` con `.tmx`
- [ ] `gridX` y `gridY` son correctos
- [ ] `targetX` y `targetY` son válidos
- [ ] Hay portal de retorno en el mapa destino

**Zonas (opcional):**
- [ ] SpawnZones tiene `name` y `enemyTypes`
- [ ] `encounterChance` es razonable (0.01-0.05)
- [ ] `dangerLevel` está definido

**Barreras (opcional):**
- [ ] Capa se llama `ConditionalBarriers`
- [ ] Tiene al menos un requisito (level, boss, o quest)
- [ ] `blockedMessage` está definido

---

¡Con esta referencia tienes todo lo necesario para crear mapas complejos! 🎮
