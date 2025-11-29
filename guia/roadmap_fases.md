# Renegade Dungeon - Guía de Proyecto y Roadmap

Este documento resume el estado actual del proyecto, lo que se ha implementado hasta ahora y los pasos siguientes para continuar el desarrollo.

---

## ✅ Estado Actual (Lo que ya funciona)

El juego tiene un **Core Loop** funcional (Exploración -> Combate -> Loot -> Progreso) y es compatible con **Web y Móvil**.

### 1. Sistemas Principales
- **Exploración:** Movimiento isométrico, niebla de guerra, transiciones entre mapas (Cementerio -> Dungeon).
- **Combate:** Sistema por turnos con iniciativa, múltiples enemigos, habilidades y cálculo de daño (Atque - Defensa).
- **Inventario y Equipo:** Sistema completo para recoger items, equipar armas/armaduras y ver estadísticas.
- **Persistencia (Guardado):**
    - **Local:** Usa Hive para guardar en disco (funciona en Web y Nativo).
    - **Nube:** Sincronización básica preparada (estructura lista).
    - **Auto-Guardado:** Al cambiar de zona y al salir al menú.

### 2. Interfaz (UI)
- **HUD:** Barra de vida/maná, minimapa y nivel siempre visibles.
- **Menús:** Menú Principal, Selección de Slot (con video de fondo), Pausa, Inventario, Tienda de Gemas.
- **Feedback:** Diálogos de barreras, notificaciones de loot, pantalla de victoria/derrota.

### 3. Correcciones Recientes (Críticas)
- **Web Autoplay:** Se arregló el error que impedía reproducir música/video en Web al salir al menú.
- **Persistencia al Cerrar:** Ahora el juego fuerza el guardado en disco (`flush`) para no perder datos si se cierra la app bruscamente.
- **Visuales:** Se arregló el glitch donde el mapa se veía detrás del menú principal.

---

## 🗺️ Roadmap de Fases

### ✅ Fase 1: Core Gameplay (Completado)
- [x] Generación de Mapas (Tiled)
- [x] Movimiento y Colisiones
- [x] Combate Básico
- [x] Cámara

### ✅ Fase 2: Sistemas RPG (Completado)
- [x] Stats (HP, MP, XP, Nivel)
- [x] Inventario y Loot
- [x] Base de Datos de Items

### ✅ Fase 3: Contenido (Completado)
- [x] Enemigos (Goblin, Slime, Bat, Skeleton)
- [x] Cofres y NPCs
- [x] Bosses (Minotauro - Lógica base)

### ✅ Fase 4: Fundamentos Técnicos (Completado)
- [x] Persistencia Web/Local (Hive)
- [x] Estructura de Guardado (JSON)

### ✅ Fase 5: Narrativa Base (Completado)
- [x] Intro y Spawn en Cementerio (ver que aparezca correctamente)
- [x] Transiciones de Mapa

### 🛠️ Fase 6: Estabilización y Corrección de Errores (Completado)
- [x] **Lógica de Combate:**
    - Se arregló que enemigos muertos siguieran atacando.
    - Se arregló el "doble ataque" del jugador (spam de habilidades).
    - Se corrigió la finalización del combate al morir el último enemigo.
- [x] **Persistencia Robusta (Save/Load):**
    - **Web:** Implementado soporte para IndexedDB (sin path_provider).
    - **Windows:** Implementado guardado en `Documents` para evitar pérdida de datos al reiniciar.
    - **UI:** Añadido botón manual de "Guardar" en el menú de pausa.
- [x] **Estabilidad de Carga:**
    - **Web Freeze:** Se arregló la pantalla negra al cargar (la música ya no bloquea la carga).
    - **Loading UI:** Se mejoró el feedback visual ("Loading World..." en ámbar).
- [x] **Estructura del Código:**
    - Restaurada la integridad de `RenegadeDungeonGame.dart`.
    - Corregidos errores críticos de linter (`isPlayerReadyNotifier`).
- [x] **Correcciones de Carga y Navegación (Noviembre 2025):**
    - **Map Loading:** Solucionado el bug donde `zone_test.tmx` fallaba al cargar y hacía fallback a `dungeon.tmx` (LateInitializationError).
    - **Item Duplication:** Arreglado el problema de duplicación de items iniciales al cargar partida.
    - **Intro Screen:** Implementado auto-skip inteligente para partidas cargadas, evitando que la intro se repita.
    - **Router:** Solucionado el problema de navegación en cargas consecutivas (pantalla negra/congelada).
    - **Boss Persistence:** Implementado guardado de jefes derrotados para desbloquear barreras permanentemente.

---

## 🔮 Pasos Siguientes (Para continuar en la escuela)

### Próxima Sesión: Contenido de Jefe
- [ ] **Diseño de Nivel:** Crear área específica para el Jefe en Tiled (`boss_area.tmx`).
- [ ] **Scripting:** Configurar el trigger de inicio de combate (`startBossCombat`).

### Fase 7: Audio y Atmósfera (Prioridad Media)
- [ ] **Sistema de Música Dinámica:** Cambiar música suavemente entre Exploración y Combate.
- [ ] **SFX:** Añadir sonidos de pasos, golpes, abrir cofres, UI.

### Fase 8: Narrativa y Misiones (Prioridad Alta)
- [ ] **Sistema de Quests:** Crear estructura para misiones (Matar X enemigos, Encontrar objeto Y).

### Fase 9: Optimización (Prioridad Baja)
- [ ] **Sprite Atlases:** Unificar imágenes para mejorar rendimiento.
- [ ] **Pantallas de Carga:** Mejorar la barra de carga al iniciar.

### Fase 10: Lanzamiento
- [ ] **Analytics:** Integrar Firebase Analytics.
- [ ] **Ads:** Integrar AdMob (opcional).
- [ ] **Build:** Generar APK/IPA y Web build final.

---

## 📝 Notas Técnicas para el Desarrollador

### Archivos Clave
- `lib/game/renegade_dungeon_game.dart`: El "cerebro" del juego. Maneja el ciclo de vida, actualizaciones y lógica global.
- `lib/services/offline_storage_service.dart`: Maneja el guardado en Hive. Si hay problemas de datos, revisa aquí.
- `lib/ui/pause_menu_ui.dart`: Lógica del menú de pausa y salida.
- `lib/components/combat_manager.dart`: Lógica del sistema de combate.

### Comandos Útiles
- **Correr en Chrome:** `flutter run -d chrome --web-renderer html` (o `canvaskit` para mejor rendimiento pero más peso).
- **Correr en Windows:** `flutter run -d windows`

### Consejos
- Si añades nuevos campos al guardado, recuerda actualizar `PlayerSaveData.dart` tanto en `toJson` como en `fromJson`.
- Para editar mapas, usa **Tiled** y guarda los archivos `.tmx` en `assets/tiles`.
