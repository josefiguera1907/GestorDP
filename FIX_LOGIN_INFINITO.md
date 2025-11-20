# Fix: Login Infinito / App se Reinicia al Login

## Problema Identificado

Cuando el usuario intentaba hacer login con credenciales correctas (admin/admin123), la app se **reiniciaba completamente**, limpiando los campos del formulario y volviendo a la pantalla de login sin mostrar errores.

### Síntomas:
- Ingresar credenciales → Presionar "Iniciar Sesión"
- Aparece círculo de carga brevemente
- La pantalla de login se recarga con campos vacíos
- No se muestra ningún error
- No hay navegación al HomeScreen

## Causa Raíz (Actualizada - v5)

**DOS problemas críticos:**

### 1. Ciclo infinito de `checkSession()`

El problema inicial estaba en `lib/main.dart` línea 61:

```dart
@override
void initState() {
  super.initState();
  // Verificar sesión al iniciar
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AuthProvider>().checkSession();
  });
}
```

### ¿Por qué causaba el problema?

1. **Primera llamada a `checkSession()`**: Se ejecuta en `initState` cuando la app inicia
2. **`checkSession()` llama a `notifyListeners()`**: Esto notifica a todos los widgets escuchando
3. **El `Consumer2<ThemeProvider, AuthProvider>` se reconstruye**: Porque AuthProvider notificó cambios
4. **`initState` NO se ejecuta de nuevo** (solo se ejecuta una vez), PERO...
5. **Cualquier otro cambio en AuthProvider** (como durante el login) causa más reconstrucciones
6. **Cada reconstrucción puede causar efectos secundarios** que interfieren con el flujo de login

Además, `checkSession()` se estaba ejecutando **sin control**, potencialmente múltiples veces, causando:
- Conflictos con el proceso de login
- Reconstrucciones innecesarias
- Pérdida del estado del formulario

### 2. MaterialApp.home cambiando durante el login ⚠️ (PROBLEMA CRÍTICO)

En `lib/main.dart` líneas 88-92:

```dart
home: authProvider.isLoading
    ? const Scaffold(body: Center(child: CircularProgressIndicator()),)
    : authProvider.isAuthenticated
        ? Builder(...HomeScreen...)
        : const LoginScreen(),
```

**El flujo roto era:**

1. Usuario presiona "Iniciar Sesión"
2. `login()` en AuthProvider llama `_isLoading = true` y `notifyListeners()`
3. **MaterialApp se reconstruye** porque AuthProvider notificó
4. `MaterialApp.home` ve `isLoading = true` → **muestra CircularProgressIndicator**
5. **LoginScreen es DESTRUIDO** (ya no es el `home`)
6. Login termina exitosamente, `_isLoading = false`, `_isAuthenticated = true`
7. MaterialApp se reconstruye de nuevo, `home` debería ser HomeScreen
8. **PERO** el `Navigator.pushReplacement()` en LoginScreen (línea 53) intenta navegar desde un widget que **YA NO EXISTE**
9. Resultado: la navegación falla silenciosamente y la app vuelve a LoginScreen

**Este era el bug principal que causaba el "reinicio"**

## Solución Implementada (v5)

### Fix 1: Flag de control para `checkSession()`

Agregué un **flag de control** (`_hasCheckedSession`) en `AuthProvider` para asegurar que `checkSession()` se ejecute **exactamente una vez**:

### Cambios en `lib/presentation/providers/auth_provider.dart`:

```dart
class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _hasCheckedSession = false; // ← NUEVO FLAG

  // ...

  Future<void> checkSession() async {
    // ← NUEVA VALIDACIÓN
    if (_hasCheckedSession) {
      print('⚠️ Session already checked, skipping...');
      return;
    }

    print('🔍 Checking session...');
    _hasCheckedSession = true;
    _isLoading = true;
    notifyListeners();

    try {
      // ... lógica existente
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _hasCheckedSession = false; // ← RESETEAR FLAG en logout

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');

    notifyListeners();
  }
}
```

### ¿Por qué funciona esta solución?

1. **`_hasCheckedSession = false` al inicio**: Permite que se verifique la sesión la primera vez
2. **`_hasCheckedSession = true` después del primer check**: Previene llamadas subsecuentes
3. **Resetear en `logout()`**: Permite verificar la sesión nuevamente después de cerrar sesión
4. **No interfiere con el login**: El login tiene su propio flujo independiente

### Fix 2: NO cambiar `_isLoading` durante el login ⭐

Modificado `login()` en `AuthProvider` para **NO modificar `_isLoading`**:

```dart
// ANTES (ROTO):
Future<bool> login(String username, String password) async {
  _isLoading = true;  // ❌ ESTO CAUSA QUE MaterialApp.home CAMBIE
  notifyListeners();
  // ... resto del código
}

// DESPUÉS (CORRECTO):
Future<bool> login(String username, String password) async {
  // ✅ NO modificar _isLoading
  // El LoginScreen maneja su propio estado de loading local

  try {
    final user = await _userRepository.authenticate(username, password);

    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;  // Solo cambiar esto

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user.id!);

      notifyListeners();  // MaterialApp.home cambiará a HomeScreen automáticamente
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}
```

**Por qué funciona:**
- `_isLoading` solo se usa para la **verificación inicial de sesión** al abrir la app
- Durante el login, el `LoginScreen` maneja su propio estado de loading **localmente**
- Cuando `login()` retorna `true` y actualiza `_isAuthenticated = true`, el `Consumer2` en `main.dart` automáticamente cambia de LoginScreen a HomeScreen
- **NO hay navegación manual**, todo es reactivo

### Fix 3: Remover navegación manual del LoginScreen

Modificado `login_screen.dart` para **NO usar Navigator.pushReplacement**:

```dart
// ANTES (ROTO):
if (success) {
  ScaffoldMessenger.of(context).showSnackBar(...);

  Navigator.of(context).pushReplacement(  // ❌ Navegar desde widget destruido
    MaterialPageRoute(builder: (context) => const HomeScreen()),
  );
}

// DESPUÉS (CORRECTO):
if (success) {
  // Login exitoso - NO navegar manualmente
  // El Consumer2 en main.dart se encargará de mostrar HomeScreen automáticamente
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('✅ Login exitoso'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 1),
    ),
  );
  // El MaterialApp.home cambiará automáticamente porque isAuthenticated = true
}
```

**Por qué funciona:**
- Cuando `isAuthenticated = true`, el `Consumer2` detecta el cambio automáticamente
- `MaterialApp.home` cambia de `LoginScreen` a `HomeScreen` sin navegación manual
- No hay conflicto de navegación porque no estamos intentando navegar desde un widget destruido

## Flujo Correcto Ahora

### Al iniciar la app:
1. `initState()` se ejecuta → llama a `checkSession()`
2. `checkSession()` verifica flag → es `false`, procede
3. Marca flag como `true`
4. Verifica SharedPreferences para sesión guardada
5. Actualiza estado y notifica
6. **Subsecuentes reconstrucciones NO ejecutan checkSession de nuevo**

### Al hacer login (NUEVO FLUJO v5):
1. Usuario ingresa credenciales y presiona botón
2. `LoginScreen` establece su propio `_isLoading = true` (local al widget)
3. Llama a `authProvider.login()` (que **NO modifica `_isLoading` del provider**)
4. `login()` autentica con la base de datos
5. Si es exitoso:
   - Actualiza `_isAuthenticated = true`
   - Guarda sesión en SharedPreferences
   - Llama `notifyListeners()`
6. `Consumer2` en `main.dart` detecta el cambio
7. `MaterialApp.home` ve que `isAuthenticated = true`
8. **MaterialApp.home cambia automáticamente de LoginScreen a HomeScreen**
9. `LoginScreen` muestra SnackBar verde brevemente antes de ser reemplazado
10. ✅ **Login exitoso sin reinicios, sin navegación manual**

### Al hacer logout:
1. Usuario hace logout
2. `logout()` limpia estado y **resetea `_hasCheckedSession = false`**
3. Si el usuario vuelve a iniciar la app, puede verificar sesión de nuevo

## Beneficios

✅ **Elimina el ciclo infinito de reconstrucciones**
✅ **Permite que el login funcione correctamente**
✅ **Mantiene la funcionalidad de verificar sesión al inicio**
✅ **Permite re-verificar sesión después de logout**
✅ **Mejora el rendimiento** (menos llamadas innecesarias a checkSession)

## Testing

Para verificar que funciona:

1. **Login inicial**:
   - Ingresar: usuario: `admin`, contraseña: `admin123`
   - Presionar "Iniciar Sesión"
   - Debe navegar a HomeScreen
   - Debe mostrar SnackBar verde: "✅ Login exitoso"

2. **Sesión persistente**:
   - Cerrar la app completamente
   - Volver a abrir
   - Debe ir directamente a HomeScreen (sin pedir login)

3. **Logout y re-login**:
   - Hacer logout
   - Debe volver a LoginScreen
   - Ingresar credenciales de nuevo
   - Debe funcionar el login

4. **Credenciales incorrectas**:
   - Ingresar credenciales inválidas
   - Debe mostrar SnackBar rojo: "❌ Usuario o contraseña incorrectos"
   - Debe mostrar AlertDialog con el error

## Archivos Modificados

- `lib/presentation/providers/auth_provider.dart`: Agregado flag `_hasCheckedSession`
- `lib/presentation/screens/login_screen.dart`: Mejorado manejo de errores con SnackBars
- `lib/data/repositories/user_repository.dart`: Agregado logging detallado

## Notas Técnicas

### ¿Por qué no usar `didChangeDependencies`?
`didChangeDependencies` se ejecuta múltiples veces cuando las dependencias cambian, lo que causaría el mismo problema.

### ¿Por qué no remover `checkSession` del initState?
Necesitamos verificar si hay una sesión guardada al iniciar la app para llevar al usuario directamente al HomeScreen.

### ¿Por qué un flag en lugar de otros métodos?
- Simple y efectivo
- No requiere cambios en la arquitectura
- Fácil de mantener
- No afecta otros flujos

## Versión

**Versión corregida**: v5 (FIX COMPLETO)
**APK generado**: `paqueteria_app_LOGIN_FIXED_v5_FINAL.apk`
**Fecha**: 2025-10-15

## Archivos Modificados (v5)

1. **`lib/presentation/providers/auth_provider.dart`**:
   - Agregado flag `_hasCheckedSession` para prevenir múltiples checks
   - **REMOVIDO** `_isLoading = true/false` del método `login()`
   - Reseteo de flag en `logout()`

2. **`lib/presentation/screens/login_screen.dart`**:
   - **REMOVIDA** navegación manual con `Navigator.pushReplacement()`
   - El cambio de pantalla ahora es completamente automático/reactivo

3. **`lib/data/repositories/user_repository.dart`**:
   - Agregado logging detallado (para debugging)

## Diferencia Clave entre v4 y v5

- **v4**: Solo arregló el problema de `checkSession()` infinito, pero seguía teniendo el problema de `MaterialApp.home` cambiando durante el login
- **v5**: Arregla AMBOS problemas - ahora el login funciona completamente
