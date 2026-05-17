# Guía de Contribución

Gracias por contribuir al proyecto. Este documento explica cómo trabajar en el repositorio de forma consistente con el resto del equipo.

---

## Índice

1. [Configurar el entorno](#1-configurar-el-entorno)
2. [Convención de branches](#2-convención-de-branches)
3. [Convención de commits](#3-convención-de-commits)
4. [Cómo abrir un PR](#4-cómo-abrir-un-pr)
5. [Checks obligatorios](#5-checks-obligatorios)
6. [Reglas de merge](#6-reglas-de-merge)

---

## 1. Configurar el entorno

Seguí la guía completa en [docs/setup.md](docs/setup.md). Incluye instalación de Flutter, Android Studio, Firebase y todos los pasos necesarios para correr la app localmente.

---

## 2. Convención de branches

| Rama | Propósito |
|---|---|
| `main` | Producción estable — solo via PR aprobado |
| `develop` | Integración continua del equipo |
| `feature/equipo-a/<nombre>` | Features Equipo A (Auth, Roles) |
| `feature/equipo-b/<nombre>` | Features Equipo B (UI, Reportes) |
| `feature/equipo-c/<nombre>` | Features Equipo C (NLP, Notificaciones) |
| `fix/<nombre>` | Corrección de bugs |
| `chore/<nombre>` | Tareas de infraestructura, docs, config |

**Ejemplos:**
```
feature/equipo-a/t-auth-01-registro-vecinos
feature/equipo-b/t-rep-02-boton-reporte-rapido
fix/t-auth-02-login-developer-error
chore/actualizar-dependencias
```

Nunca trabajar directamente sobre `main` o `develop`.

---

## 3. Convención de commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/) con el ID de la tarea Jira obligatorio:

```
<tipo>: [T-XXX-00] Descripción corta en presente
```

**Tipos válidos:**

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `docs` | Cambios en documentación |
| `chore` | Build, dependencias, configuración |
| `test` | Agregar o modificar tests |
| `ci` | Cambios en workflows de CI/CD |
| `refactor` | Refactoring sin cambio de comportamiento |

**Ejemplos:**
```
feat: [T-AUTH-01] Implementar registro de vecinos informantes
fix: [T-AUTH-02] Corregir DEVELOPER_ERROR en login Android
docs: [T-INF-06] Actualizar guía de setup con pasos de Firebase
test: [T-AUTH-01] Agregar tests unitarios para RegisterUseCase
```

Los PRs con commits que no sigan este formato van a fallar el check automático.

---

## 4. Cómo abrir un PR

1. Asegurate de estar actualizado con `develop`:
   ```powershell
   git fetch origin
   git rebase origin/develop
   ```

2. Corré los checks localmente antes de pushear:
   ```powershell
   flutter analyze
   flutter test
   dart format --set-exit-if-changed .
   ```

3. Pusheá tu rama:
   ```powershell
   git push -u origin feature/equipo-x/nombre-tarea
   ```

4. Abrí el PR en GitHub apuntando a `develop` (no a `main`)

5. El título del PR debe seguir el mismo formato que los commits:
   ```
   feat: [T-AUTH-01] Implementar registro de vecinos informantes
   ```

6. Completá la descripción del PR explicando qué cambia y cómo probarlo

7. Asigná al menos un reviewer del equipo

---

## 5. Checks obligatorios

Todos los PRs corren automáticamente:

| Check | Qué verifica |
|---|---|
| **Validar título del PR** | Que el título incluya `[T-XXX-00]` |
| **Flutter analyze & test** | Linter, formato de código y tests unitarios |

Un PR no puede mergearse si alguno de estos checks falla.

Si un check falla, corregí el problema localmente y pusheá — los checks se vuelven a correr automáticamente.

---

## 6. Reglas de merge

- `develop` → requiere que pasen los checks, sin review obligatorio
- `main` → requiere que pasen todos los checks **y** al menos **1 review aprobado**
- Nunca hacer force push sobre `main` o `develop`
- Siempre hacer merge desde `develop` a `main`, nunca desde una feature branch directamente
