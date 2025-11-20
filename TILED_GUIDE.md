# 🎮 Guía para Editar Mapas con Tiled

## ⚠️ IMPORTANTE: Cómo Subir Assets Correctamente

### Problema Común
Cuando editas el mapa en Tiled y usas tilesets con imágenes, Tiled **guarda rutas absolutas** de tu computadora (ej: `D:/mis_archivos/imagen.png`). Esto rompe el juego para los demás.

---

## ✅ Forma Correcta de Trabajar con Tiled

### 1. **Organiza los Archivos ANTES de Editar**

```
assets/
├── tiles/
│   ├── dungeon.tmx           (El mapa)
│   ├── dungeon_tileset.tsx   (Tileset principal)
│   └── mi_nuevo_tileset.tsx  (Nuevo tileset)
└── images/
    ├── iso_tile_export.png   (Imagen del tileset principal)
    └── mi_nuevo_tileset.png  (Imagen del nuevo tileset)
```

**REGLA DE ORO**: Las imágenes `.png` pueden estar en `assets/images/` o `assets/tiles/`, pero **siempre usa rutas relativas**

---

### 2. **Al Crear un Nuevo Tileset en Tiled**

1. **Abre Tiled**
2. **Carga el mapa**: `dungeon.tmx`
3. **Nuevo Tileset** → Click derecho en panel de Tilesets → "New Tileset"
4. **IMPORTANTE**: Cuando selecciones la imagen:
   - ✅ **Navega a**: `assets/tiles/`
   - ✅ **Selecciona la imagen** que YA está en esa carpeta
   - ❌ **NO uses imágenes** de otras carpetas (Desktop, Downloads, D:/, etc.)

5. **Al guardar el tileset**:
   - Guárdalo en `assets/tiles/` con extensión `.tsx`
   - Asegúrate que esté al lado de su imagen `.png`

---

### 3. **Verificar Antes de Hacer Commit**

Abre el archivo `.tsx` en un editor de texto y verifica:

```xml
<!-- ✅ CORRECTO: Ruta relativa (misma carpeta) -->
<image source="mi_imagen.png" width="256" height="256"/>

<!-- ✅ CORRECTO: Ruta relativa (carpeta images) -->
<image source="../images/iso_tile_export.png" width="256" height="256"/>

<!-- ❌ INCORRECTO: Ruta absoluta -->
<image source="D:/mis_archivos/Tiled/mi_imagen.png" width="256" height="256"/>
```

**Si ves rutas como `C:/` o `D:/`**: Cámbialas a rutas relativas como `../images/archivo.png`

---

### 4. **Subir a GitHub**

```bash
# 1. Añadir TODOS los archivos necesarios
git add assets/tiles/mi_nuevo_tileset.tsx
git add assets/tiles/mi_nuevo_tileset.png
git add assets/tiles/dungeon.tmx

# 2. Commit con mensaje descriptivo
git commit -m "feat: añadido tileset de [descripción] al mapa"

# 3. Push
git push origin main
```

---

## 🔧 Cómo Arreglar si Ya Subiste Mal

Si alguien ya subió cambios con rutas absolutas:

```bash
# 1. Edita manualmente los archivos .tsx
# Cambia las rutas absolutas por relativas

# 2. Verifica que las imágenes PNG estén en assets/tiles/
# Si no están, añádelas

# 3. Subir el fix
git add assets/tiles/*.tsx
git add assets/tiles/*.png
git commit -m "fix: corregidas rutas de tilesets"
git push origin main
```

---

## 📋 Checklist Antes de Push

- [ ] ¿Las imágenes `.png` están en `assets/images/` o `assets/tiles/`?
- [ ] ¿Los archivos `.tsx` tienen rutas relativas correctas (ej: `../images/archivo.png`)?
- [ ] ¿El juego corre sin errores en mi máquina?
- [ ] ¿Hice `git add` de TODOS los archivos necesarios (`.tsx` Y `.png`)?

---

## 🆘 Si Algo Sale Mal

1. **Revisa la consola del navegador** (F12) para ver el error
2. **Busca rutas absolutas** en los archivos `.tsx`
3. **Verifica que existan** los archivos `.png` referenciados
4. **Pregunta en el grupo** si no sabes cómo arreglarlo

---

## 💡 Tips Adicionales

- **Backup**: Antes de editar el mapa, haz una copia de `dungeon.tmx`
- **Comunica**: Avisa en el grupo cuando vayas a editar el mapa
- **Pull Primero**: Siempre haz `git pull` antes de editar
- **Prueba Local**: Verifica que `flutter run -d edge` funcione antes de hacer push

---

**Creado**: 2025-11-20  
**Última actualización**: Después del incidente de rutas absolutas en tilesets
