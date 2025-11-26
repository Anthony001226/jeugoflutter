# 🔐 Cloud Save & Authentication Roadmap

## TL;DR - Cuándo Implementar

**Respuesta corta**: Entre **Phase 5 y Phase 6** (después de tener contenido jugable)

**Razón**: Necesitas que el juego tenga suficiente contenido para que valga la pena guardar progreso en la nube. Si implementas cloud save antes de tener un juego interesante, es esfuerzo desperdiciado.

---

## 📊 Momento Óptimo (Recomendación)

### ✅ Implementar DESPUÉS de:
- ✅ Phase 3: Combat completo
- ✅ Phase 4: World Building (zonas, portales, NPCs)
- ✅ Phase 4.5: Quest system básico
- ✅ Phase 5: Equipment & Loot funcionando

### ⚠️ Implementar ANTES de:
- Phase 8: Content & Balance (balanceo final)
- Phase 9: Polish (beta pública)
- Phase 10: Endgame

### 🎯 **Punto ideal: Final de Phase 5 / Inicio de Phase 6**

**Por qué este momento:**
1. Ya tienes ~5-10 horas de contenido jugable
2. El jugador tiene algo que "perder" (progreso, items, quests)
3. El save system local ya está probado y estable
4. Sabes exactamente qué datos necesitas guardar

---

## 🗺️ Implementación por Etapas

### Stage 1: Preparación (Phase 5)
**Duración**: 2-3 horas

**Objetivo**: Asegurar que tu save system local esté bien estructurado

- [ ] Auditar qué datos guardas actualmente
- [ ] Crear clase `SaveData` serializable (JSON)
- [ ] Verificar que todo se guarde/cargue correctamente
- [ ] Testing exhaustivo de save/load

**Archivos a modificar**:
- `lib/models/save_data.dart` (refactor)
- `lib/utils/save_manager.dart` (limpiar)

---

### Stage 2: Backend Setup (Inicio Phase 6)
**Duración**: 4-6 horas

**Objetivo**: Configurar servicio de backend

#### Opción A: Firebase (Recomendado para indie)
**Pros**:
- Gratis hasta 50k usuarios activos
- Auth con email/password incluido
- Firestore para guardar datos
- Fácil de configurar

**Setup**:
```bash
# 1. Agregar dependencias
flutter pub add firebase_core firebase_auth cloud_firestore

# 2. Configurar Firebase en proyecto
flutterfire configure
```

**Tareas**:
- [ ] Crear proyecto en Firebase Console
- [ ] Habilitar Authentication (Email/Password)
- [ ] Configurar Firestore Database
- [ ] Reglas de seguridad básicas

#### Opción B: Supabase (Alternativa open-source)
**Pros**:
- Open source
- PostgreSQL real (más flexible)
- Self-hostable

**Cons**:
- Más complejo de configurar
- Menos documentación para Flutter

#### Opción C: Custom Backend
**Solo si**:
- Tienes experiencia con backend
- Quieres control total
- Planeas monetización compleja

**No recomendado** para fase temprana.

---

### Stage 3: Authentication UI (Phase 6)
**Duración**: 3-4 horas

**Objetivo**: Pantallas de login/registro

**Pantallas a crear**:
1. **Login Screen**
   - Email + Password
   - "Forgot Password?" link
   - "Sign Up" button
   
2. **Register Screen**
   - Email + Password + Confirm Password
   - Terms & Conditions checkbox
   - Email verification
   
3. **Profile Screen**
   - Ver email asociado
   - Change password
   - Logout button

**Archivos nuevos**:
- `lib/ui/auth/login_screen.dart`
- `lib/ui/auth/register_screen.dart`
- `lib/ui/auth/profile_screen.dart`
- `lib/services/auth_service.dart`

**Flow**:
```
App Launch
    ↓
¿Usuario loggeado?
    ├─ SÍ → Main Menu (normal)
    └─ NO → Login Screen
              ↓
           ¿Tiene cuenta?
              ├─ SÍ → Login → Main Menu
              └─ NO → Register → Email Verification → Main Menu
```

---

### Stage 4: Cloud Save Integration (Phase 6)
**Duración**: 4-5 horas

**Objetivo**: Guardar/cargar desde la nube

**Tareas**:
- [ ] Crear `CloudSaveService`
- [ ] Upload save data a Firestore
- [ ] Download save data al login
- [ ] Merge local + cloud (conflict resolution)
- [ ] Auto-save cada X minutos
- [ ] Manual "Save to Cloud" button

**Estructura Firestore**:
```
users/
  └─ {userId}/
      └─ saves/
          ├─ slot1/
          │   ├─ playerStats: {...}
          │   ├─ inventory: [...]
          │   ├─ quests: {...}
          │   └─ metadata: {lastSaved, version}
          ├─ slot2/
          └─ slot3/
```

**Archivos a modificar**:
- `lib/services/cloud_save_service.dart` (NEW)
- `lib/game/renegade_dungeon_game.dart` (integrar auto-save)
- `lib/ui/slot_selection_menu.dart` (mostrar cloud saves)

---

### Stage 5: Conflict Resolution (Phase 6)
**Duración**: 2-3 horas

**Objetivo**: Manejar saves desincronizados

**Escenarios problemáticos**:
1. Usuario juega offline → datos desactualizados
2. Usuario juega en 2 dispositivos → conflicto
3. Usuario borra save local pero existe en cloud

**Estrategia**:
- **Timestamp-based**: Guardar fecha de última modificación
- **User choice**: Mostrar diálogo "¿Usar save local o cloud?"
- **Merge intelligent**: Combinar si es posible (ejemplo: items únicos)

**UI**:
```
⚠️ Save Conflict Detected
Local Save: Level 15, Last Played 2 hours ago
Cloud Save: Level 12, Last Played yesterday

[Use Local]  [Use Cloud]  [Cancel]
```

---

### Stage 6: Polish & Edge Cases (Phase 7)
**Duración**: 2-3 horas

**Tareas**:
- [ ] Loading states (spinners during upload/download)
- [ ] Error handling (sin internet, server down)
- [ ] Retry logic con exponential backoff
- [ ] Offline mode (permitir jugar sin conexión)
- [ ] Success/error toasts ("Saved to cloud ✓")

**Edge cases**:
- [ ] Qué pasa si se pierde conexión mid-save?
- [ ] Qué pasa si Firestore está caído?
- [ ] Límite de tamaño de save data (Firestore = 1MB/doc)

---

## 💰 Consideraciones de Costo

### Firebase Pricing (Free Tier)
- **Authentication**: 50k usuarios gratis
- **Firestore**: 
  - 50k reads/day
  - 20k writes/day
  - 1GB storage
- **Bandwidth**: 10GB/month

**Estimación para tu juego**:
- 1 save = ~50KB (JSON serializado)
- 1000 usuarios activos = ~200 writes/day
- **Conclusión**: Gratis hasta ~5k-10k jugadores

### Cuándo pagas:
- Cuando superes free tier
- ~$25-50/mes con 20k usuarios
- Escalable hasta $100-500/mes con 100k+

---

## 🚨 Errores Comunes a Evitar

### ❌ Error 1: Implementar muy temprano
**Síntoma**: Gastas semanas en auth cuando el juego aún no es divertido

**Solución**: Espera a tener contenido jugable (Phase 5+)

### ❌ Error 2: No versionar los saves
**Síntoma**: Cambias estructura de datos y rompes saves antiguos

**Solución**: 
```dart
class SaveData {
  static const int CURRENT_VERSION = 2;
  int version;
  
  // Migration logic
  SaveData.fromJson(Map<String, dynamic> json) {
    version = json['version'] ?? 1;
    if (version < CURRENT_VERSION) {
      _migrate(json);
    }
  }
}
```

### ❌ Error 3: No encriptar datos sensibles
**Síntoma**: Jugadores hackean sus stats editando Firestore

**Solución**: 
- Encriptar stats críticos (level, gold, items)
- Validar server-side antes de guardar
- Firestore rules strictas

### ❌ Error 4: No testear offline
**Síntoma**: App crashea sin internet

**Solución**: Siempre tener fallback a local save

---

## 📋 Checklist Completa

### Pre-requisitos
- [ ] Save system local funciona perfectamente
- [ ] Tienes mínimo 5 horas de contenido jugable
- [ ] Stats/inventory/quests son estables (no cambiarán mucho)

### Implementation
- [ ] Backend configurado (Firebase/Supabase)
- [ ] Authentication UI completa
- [ ] Cloud save upload/download
- [ ] Conflict resolution
- [ ] Auto-save cada 5 minutos
- [ ] Offline mode funcional

### Testing
- [ ] Login/Register/Logout fluyen correctamente
- [ ] Save sincroniza entre dispositivos
- [ ] Funciona sin internet (local save)
- [ ] Conflictos se resuelven correctamente
- [ ] Email verification funciona

### Security
- [ ] Firestore rules configuradas
- [ ] Datos sensibles encriptados
- [ ] Rate limiting en auth (anti-spam)

---

## 🎯 Resumen Ejecutivo

### Timing Recomendado
**Implementa entre Phase 5 y Phase 6** (cuando tengas ~40-50% del juego completo)

### Esfuerzo Total
**15-20 horas** divididas en:
- Backend setup: 4-6h
- Auth UI: 3-4h
- Cloud save logic: 4-5h
- Conflict resolution: 2-3h
- Testing & polish: 2-3h

### ROI (Return on Investment)
- **Alto**: Aumenta retención un ~30-50%
- **Medio-Alto**: Permite jugar en múltiples dispositivos
- **Crítico para**: Monetización futura (compras vinculadas a cuenta)

### Alternativa Más Simple
Si quieres algo **más rápido ahora** (Phase 4):
- Solo implementa login con Google/Apple (1-2h)
- Guarda un hash del email en save local
- NO sincronices a la nube aún
- Al menos tienes "account ownership"

---

## 🔗 Recursos Útiles

### Firebase
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Supabase
- [Supabase Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)

### Tutoriales
- [Firebase Auth + Firestore Tutorial](https://www.youtube.com/watch?v=rWamixHIKmQ)
- [Cloud Save Best Practices](https://www.gamedeveloper.com/programming/save-game-best-practices)

---

**Próximo paso**: Terminar Phase 4 y 5 primero, luego volver a este roadmap 🚀
