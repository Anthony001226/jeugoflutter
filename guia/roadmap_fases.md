# Renegade Dungeon - Guía de Proyecto y Roadmap

Este documento resume el estado actual del proyecto, lo que se ha implementado hasta ahora y los pasos siguientes para continuar el desarrollo.

---

## ✅ Estado Actual (Lo que ya funciona)

El juego tiene un **Core Loop** funcional (Exploración -> Combate -> Loot -> Progreso) y es compatible con **Web y Móvil**.

### 1. Sistemas Principales
- **Exploración:** Movimiento isométrico, niebla de guerra, transiciones entre mapas.
- **Combate:** Sistema por turnos, múltiples enemigos, habilidades, cálculo de daño.
- **Economía:** Oro, drops de enemigos, tienda de gemas (debug), penalización de muerte.
- **Persistencia (Guardado):**
    - **Local:** Hive (Web/Nativo).
    - **Nube:** Firebase Auth & Firestore (Sincronización de slots).
    - **Auto-Guardado:** Al cambiar de zona, salir al menú y background (móvil).

### 2. Interfaz (UI)
- **HUD:** Barra de vida/maná, minimapa (zoom mejorado) y nivel.
- **Menús:** Menú Principal, Selección de Slot (con fallback PNG en móvil), Pausa, Inventario, Tienda.
- **Feedback:** Diálogos, notificaciones de loot, pantalla de victoria/derrota.

### 3. Correcciones Recientes (Críticas)
- **Mobile Video Crash:** Implementado fallback a imágenes estáticas (`.png`) en Android/iOS para evitar crashes con `VideoPlayer`.
- **Economía:** Implementado sistema de oro, drops de enemigos y penalización de muerte (75% pérdida vs 0% con gemas).
- **Cloud Save:** Integración completa con Firebase para guardar progreso en la nube.

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

### ✅ Fase 3: Contenido Base (Completado)
- [x] Enemigos (Goblin, Slime, Bat, Skeleton)
- [x] Cofres y NPCs
- [x] Bosses (Lógica base y persistencia)

### ✅ Fase 4: Fundamentos Técnicos (Completado)
- [x] Persistencia Web/Local (Hive)
- [x] Estructura de Guardado (JSON)
- [x] Cloud Save (Firebase)

### ✅ Fase 5: Economía y Pulido (Completado)
- [x] Sistema de Oro y Drops
- [x] Tienda de Gemas (UI y Debug)
- [x] Penalización de Muerte y Revivir
- [x] Optimización Móvil (Video Fallback, UI Responsive)

---

## 🔮 Pasos Siguientes

### 🚧 Fase 6: Contenido de Jefe y Nuevas Áreas (En Progreso)
- [ ] **Diseño de Nivel (Tiled):**
    - Crear `boss_area.tmx` (30x30 tiles).
    - Capas: `Ground`, `Walls`, `Decorations`, `Objects` (Spawn, BossTrigger).
    - Portales de entrada/salida.
- [ ] **Scripting:**
    - Conectar BossTrigger con `startBossCombat`.
    - Implementar comportamiento específico del Boss (fases, habilidades).

### Fase 7: Audio y Atmósfera (Prioridad Media)
- [ ] **Sistema de Música Dinámica:** Transiciones suaves entre exploración y combate.
- [ ] **SFX:** Sonidos de pasos, golpes, UI, abrir cofres.

### Fase 8: Narrativa y Misiones (Prioridad Alta)
- [ ] **Sistema de Quests:** Estructura para misiones (Matar X, Encontrar Y).
- [ ] **Diálogos Avanzados:** NPCs con múltiples líneas y opciones.

### Fase 9: Optimización y Lanzamiento (Prioridad Baja)
- [ ] **Sprite Atlases:** Unificar imágenes.
- [ ] **Analytics:** Firebase Analytics.
- [ ] **Ads:** AdMob (opcional).
- [ ] **Build Final:** APK/IPA y Web.

---

## 📝 Notas Técnicas

### Archivos Clave
- `lib/game/renegade_dungeon_game.dart`: Lógica global.
- `lib/services/cloud_save_service.dart`: Sincronización con Firebase.
- `lib/ui/gem_shop_screen.dart`: Tienda y compras (Debug).
- `assets/videos/`: Contiene `.mp4` para Web y `.png` para Móvil.

### Comandos Útiles
- **Correr en Chrome:** `flutter run -d chrome --web-renderer html`
- **Correr en Móvil:** `flutter run -d <device_id>`
