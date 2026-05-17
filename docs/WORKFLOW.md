# Flujo de Desarrollo — App de Coordinación Comunitaria

Este documento describe el ciclo de vida completo de una tarea, desde que se asigna en Jira hasta que llega a producción.

---

## Flujo de branches

```
main          ──────────────────────────────────────────► producción
                ▲                                ▲
                │ PR aprobado + checks           │
develop       ──┴────────────────────────────────┴──────► integración
                ▲              ▲              ▲
                │              │              │
feature/A  ─────┘         feature/B     feature/C
```

- Las **feature branches** siempre salen de `develop` y vuelven a `develop`
- `develop` se mergea a `main` al final de cada sprint cuando está estable
- Nadie pushea directo a `main` ni a `develop`

---

## Ciclo de vida de una tarea

### 1. Tomar la tarea en Jira
- Ir al board de Jira y mover la tarea a **En curso**
- Anotá el ID de la tarea (ej. `T-AUTH-01`) — lo vas a necesitar en todos los commits

### 2. Crear la branch
Siempre desde `develop` actualizado:
```powershell
git checkout develop
git pull origin develop
git checkout -b feature/equipo-x/t-auth-01-nombre-descriptivo
```

### 3. Desarrollar
- Escribí el código siguiendo las guías de [CONTRIBUTING.md](../CONTRIBUTING.md)
- Commiteá frecuentemente con mensajes semánticos:
  ```
  feat: [T-AUTH-01] Agregar formulario de registro
  feat: [T-AUTH-01] Conectar formulario con Firebase Auth
  test: [T-AUTH-01] Agregar tests para RegisterUseCase
  ```
- Si modificás modelos anotados, regenerá el código:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```

### 4. Verificar localmente antes de pushear
```powershell
flutter analyze          # sin errores
flutter test             # todos los tests pasan
dart format --set-exit-if-changed .   # código formateado
```

### 5. Sincronizar con develop antes del PR
Para evitar conflictos, actualizate con lo último de `develop`:
```powershell
git fetch origin
git rebase origin/develop
```
Si hay conflictos, resolvelos y continuá el rebase:
```powershell
git add .
git rebase --continue
```

### 6. Pushear y abrir el PR
```powershell
git push -u origin feature/equipo-x/t-auth-01-nombre-descriptivo
```
Luego en GitHub:
- PR apuntando a `develop` (no a `main`)
- Título: `feat: [T-AUTH-01] Implementar registro de vecinos`
- Descripción: qué cambia, cómo probarlo, screenshots si aplica
- Asignar un reviewer

### 7. Checks automáticos
Al abrir el PR corren automáticamente:
- Validación del título
- `flutter analyze` + `flutter test`
- Verificación de formato de código

Si alguno falla, corregí localmente y pusheá — los checks se vuelven a correr solos.

### 8. Review y merge
- El reviewer aprueba o pide cambios
- Una vez aprobado y con todos los checks verdes → merge a `develop`
- **Borrar la branch** después del merge (GitHub lo hace automáticamente si está configurado)

### 9. Cerrar la tarea en Jira
- Mover la tarea a **Finalizado** en el board

---

## Merge de develop a main (fin de sprint)

Al finalizar el sprint, cuando `develop` está estable:

1. Abrir un PR de `develop` → `main`
2. Título: `release: Sprint X — descripción general`
3. Requiere **1 review aprobado** + todos los checks verdes
4. Después del merge, el workflow de CI buildea el APK de release automáticamente y lo guarda como artefacto en GitHub Actions

---

## Qué hacer si los checks fallan

### Falla `Validar título del PR`
El título no tiene el formato correcto. Editá el título del PR en GitHub para que incluya `[T-XXX-00]`.

### Falla `Flutter analyze`
```powershell
flutter analyze
```
Corregí los errores que lista y pusheá.

### Falla `Verificar formato de código`
```powershell
dart format .
git add .
git commit -m "chore: formatear código"
git push
```

### Falla `Flutter test`
```powershell
flutter test
```
Corregí los tests que fallan. Si el test era correcto y el código está mal, corregí el código.

### Falla `Verificar código generado`
```powershell
dart run build_runner build --delete-conflicting-outputs
git add .
git commit -m "chore: actualizar código generado"
git push
```

---

## Comandos de referencia rápida

```powershell
# Correr la app en el emulador
flutter run -d emulator-5554 --no-enable-impeller

# Verificar antes de commitear
flutter analyze && flutter test

# Regenerar código de modelos
dart run build_runner build --delete-conflicting-outputs

# Formatear código
dart format .

# Ver dispositivos disponibles
flutter devices

# Sincronizar con develop
git fetch origin && git rebase origin/develop
```
