# 🚪 Guía: Configurar Barreras Condicionales en Tiled

## ¿Qué son las Barreras Condicionales?

Las barreras condicionales son áreas invisibles que bloquean el paso del jugador hasta que cumpla ciertos requisitos:
- **Nivel mínimo** (ej: solo puedes pasar si eres nivel 15+)
- **Boss derrotado** (ej: solo si mataste al primer jefe)
- **Quest completada** (ej: solo si completaste una misión) - *futuro*

---

## 📋 Paso 1: Abrir tu Mapa en Tiled

1. Abre **Tiled** (el editor de mapas)
2. Abre tu archivo de mapa: `assets/tiles/dungeon.tmx`

---

## 📋 Paso 2: Crear la Capa de Barreras

### 2.1 Crear nueva capa de objetos

1. Ve al panel **Capas** (Layers) en la parte derecha
2. Click derecho en la lista de capas → **Nueva Capa** → **Capa de Objetos**
3. **Nombre de la capa**: `ConditionalBarriers` ⚠️ **Exactamente así, respetando mayúsculas**

### 2.2 Verificar nombre correcto

✅ Correcto: `ConditionalBarriers`
❌ Incorrecto: `conditionalBarriers`, `Barriers`, `conditional_barriers`

---

## 📋 Paso 3: Dibujar una Barrera

### 3.1 Seleccionar herramienta de rectángulo

1. Asegúrate de tener seleccionada la capa `ConditionalBarriers`
2. En la barra de herramientas, selecciona **Insertar Rectángulo** (Insert Rectangle)
3. Dibuja un rectángulo en el lugar donde quieres bloquear el paso

**Ejemplo**: Si quieres bloquear la entrada a una cueva, dibuja un rectángulo en la entrada.

### 3.2 Tamaño recomendado

- **Pasillo estrecho**: 1-2 tiles de ancho
- **Puerta/Entrada**: 2-3 tiles de ancho
- **Camino bloqueado**: Todo el ancho del camino

---

## 📋 Paso 4: Configurar Propiedades de la Barrera

### 4.1 Seleccionar el rectángulo

1. Click en el rectángulo que acabas de crear
2. Ve al panel **Propiedades** (Properties) en la parte derecha

### 4.2 Añadir propiedades

Click en el botón **+** (añadir propiedad) y añade las siguientes:

#### Propiedad 1: `id` (Opcional)
- **Tipo**: String
- **Valor**: Un identificador único, ej: `"granja_entrance"`
- **Para qué sirve**: Identificar esta barrera específica

#### Propiedad 2: `requiredLevel` (Opcional)
- **Tipo**: int
- **Valor**: Nivel mínimo requerido, ej: `15`
- **Para qué sirve**: El jugador debe ser nivel 15 o superior para pasar
- **Nota**: Si es `0` o no existe, no hay requisito de nivel

#### Propiedad 3: `requiredBoss` (Opcional)
- **Tipo**: String
- **Valor**: ID del boss que debe estar derrotado, ej: `"first_boss"`
- **Para qué sirve**: El jugador debe haber derrotado ese boss para pasar
- **Nota**: Si es `"none"` o no existe, no hay requisito de boss

#### Propiedad 4: `requiredQuest` (Opcional - Futuro)
- **Tipo**: String
- **Valor**: ID de la quest, ej: `"quest_001"`
- **Para qué sirve**: El jugador debe haber completado esa quest
- **Nota**: Si es `"none"` o no existe, no hay requisito de quest

#### Propiedad 5: `blockedMessage` (Recomendado)
- **Tipo**: String
- **Valor**: Mensaje que se muestra cuando está bloqueado
- **Ejemplo**: `"Necesitas ser nivel 15 y derrotar al Guardian del Panteón"`
- **Por defecto**: "No puedes pasar aún."

#### Propiedad 6: `unlockedMessage` (Opcional)
- **Tipo**: String
- **Valor**: Mensaje que se muestra la primera vez que lo desbloqueas
- **Ejemplo**: `"¡Acceso a la Granja desbloqueado!"`

---

## 📋 Ejemplos de Configuración

### Ejemplo 1: Barrera solo de Nivel
```
id: "zona_nivel_10"
requiredLevel: 10
requiredBoss: "none"
blockedMessage: "Zona peligrosa. Necesitas ser nivel 10 o superior."
unlockedMessage: "Te sientes preparado para explorar esta zona."
```

### Ejemplo 2: Barrera solo de Boss
```
id: "post_boss_area"
requiredLevel: 0
requiredBoss: "skeleton_king"
blockedMessage: "El camino está bloqueado por una energía oscura. Debes derrotar al Rey Esqueleto."
unlockedMessage: "La energía oscura se disipa. El camino está despejado."
```

### Ejemplo 3: Barrera de Nivel + Boss (Tu ejemplo)
```
id: "granja_entrance"
requiredLevel: 15
requiredBoss: "first_boss"
blockedMessage: "Necesitas nivel 15 y derrotar al Guardian del Panteón"
unlockedMessage: "¡Bienvenido a la Granja!"
```

### Ejemplo 4: Múltiples requisitos
```
id: "dungeon_final"
requiredLevel: 20
requiredBoss: "first_boss"
blockedMessage: "Solo los más fuertes pueden entrar aquí."
unlockedMessage: "La puerta del calabozo final se abre..."
```

---

## 🔧 Paso 5: Marcar un Boss como Derrotado (Código)

Para que una barrera que requiere un boss funcione, necesitas marcar ese boss como derrotado cuando lo mates.

### En el código de combate (cuando el boss muere):

```dart
// Después de derrotar al boss
if (enemyStats.currentHp.value <= 0) {
  // Si es un boss, marcarlo como derrotado
  if (enemyName == "Guardian del Panteón") {
    game.player.stats.defeatBoss("first_boss");
  }
  
  // ... resto del código de muerte
}
```

### Nombre de bosses sugeridos:
- `"first_boss"` - Primer jefe (ej: Guardian del Panteón)
- `"second_boss"` - Segundo jefe
- `"skeleton_king"` - Rey Esqueleto
- `"forest_guardian"` - Guardián del Bosque
- etc.

---

## 🎨 Tips y Buenas Prácticas

### Visual (Opcional)
Puedes poner un sprite visual de "puerta cerrada" o "barrera" en la capa normal del mapa para que el jugador sepa que hay algo ahí.

### Testing
1. Crea una barrera con `requiredLevel: 5`
2. Pon a tu jugador en nivel 1
3. Intenta pasar → debería bloquearte
4. Sube a nivel 5: Mata enemigos o usa `game.player.stats.level.value = 5` en consola
5. Intenta pasar → debería dejarte pasar

### Múltiples Barreras
Puedes tener tantas barreras como quieras en el mismo mapa. Cada una puede tener requisitos diferentes.

### Barreras Permanentes
Una vez que el jugador cumple los requisitos y pasa, la barrera queda **permanentemente desbloqueada** (no vuelve a verificar).

---

## ❓ Troubleshooting

### "No se carga mi barrera"
- ✅ Verifica que la capa se llame exactamente `ConditionalBarriers`
- ✅ Verifica que guardaste el archivo `.tmx`
- ✅ Reinicia el juego para recargar el mapa

### "La barrera no me bloquea"
- ✅ Verifica que el rectángulo esté en la posición correcta
- ✅ Verifica que las propiedades estén bien escritas (`requiredLevel`, no `required_level`)
- ✅ Mira la consola para ver mensajes de debug

### "Me bloquea pero no veo el mensaje"
- ✅ Por ahora los mensajes solo aparecen en consola (con 💬)
- ✅ En el futuro (Paso 4) se implementará un diálogo visual

---

## 📸 Resumen Visual del Flujo

```
1. Jugador intenta moverse
   ↓
2. Sistema verifica: ¿Hay barrera en esa posición?
   ↓ No → Permite movimiento
   ↓ Sí → Verifica requisitos
   ↓
3. ¿Cumple nivel requerido?
   ↓ No → BLOQUEADO (muestra mensaje)
   ↓ Sí → Continúa
   ↓
4. ¿Cumple boss requerido?
   ↓ No → BLOQUEADO (muestra mensaje)
   ↓ Sí → Continúa
   ↓
5. ✅ DESBLOQUEADO (mensaje opcional)
   Marca barrera como permanentemente abierta
```

---

## 🚀 Siguiente Paso

Una vez que configures tu primera barrera en Tiled:
1. Guarda el archivo
2. Corre el juego
3. Mira la consola para ver: `✅ Loaded X conditional barriers`
4. Intenta atravesar la barrera → deberías ver el mensaje de bloqueo

¡Listo para implementar! 🎮
