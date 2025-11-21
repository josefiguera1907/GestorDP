# Sistema de Gestión de Paquetería con Mensajería (GestorDP)

Aplicación móvil desarrollada en Flutter para la gestión de paquetería con integración de mensajería para notificaciones automatizadas.

## Características Principales

- **Gestión de Paquetes**: Registro, seguimiento y gestión de paquetes
- **Gestión de Almacenes y Ubicaciones**: Organización jerárquica del inventario
- **Mensajería Integrada**: Envío automatizado de notificaciones por WhatsApp Business API
- **Escaneo de QR**: Lectura de códigos QR para registro ágil de paquetes
- **Soporte para Dispositivos Bajos Recursos**: Optimizado para dispositivos con 1GB de RAM
- **Multiusuario**: Soporte para diferentes roles y permisos
- **Exportación de Datos**: Generación de PDFs con información de paquetes

## Tecnologías Utilizadas

- **Flutter**: Framework para desarrollo multiplataforma
- **SQLite**: Base de datos local para almacenamiento persistente
- **Provider**: Patrón de administración de estado
- **REST API**: Integración con WhatsApp Business API
- **Shared Preferences**: Almacenamiento de configuraciones locales

## Arquitectura

El proyecto sigue el patrón de arquitectura limpio con:
- **Domain**: Lógica de negocio y entidades
- **Data**: Repositorios, servicios y fuentes de datos
- **Presentation**: Screens, widgets y proveedores de estado

## Características de Rendimiento

- Optimizado para dispositivos con 1GB de RAM
- Gestión inteligente de memoria
- Configuraciones PRAGMA para SQLite en dispositivos bajos recursos
- Tamaños de cache reducidos
- Componentes ligeros para mejor respuesta táctil

## Configuración de Mensajería

La aplicación soporta dos sistemas de mensajería:
1. **META (nuevo)**: Integración con WhatsApp Business API usando plantillas
2. **Chatea (legacy)**: Sistema de mensajería anterior como respaldo

## Configuración Inicial

Para usar la funcionalidad de mensajería con META:
1. Configurar Identificador de número de teléfono en Ajustes → META
2. Configurar Token de acceso de API en Ajustes → META
3. Las plantillas se obtienen automáticamente desde su cuenta de WhatsApp Business

## Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Compilar la aplicación
flutter build apk --release

# Correr en modo debug
flutter run

# Analizar código
flutter analyze
```

## Contribuciones

Las contribuciones son bienvenidas. Por favor, asegúrese de seguir las guías de estilo de código y escribir pruebas para nuevas funcionalidades o correcciones de errores.

## Licencia

Este proyecto está licenciado bajo los términos del MIT License.