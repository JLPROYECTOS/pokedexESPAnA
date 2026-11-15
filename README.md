# IbéricoDex

Guía de campo de la fauna de la península ibérica con registro de avistamientos.
Proyecto base en Flutter (Android e iOS con el mismo código).

## Generar la APK

Este paquete contiene el código de la app (`lib/`, `assets/`, `pubspec.yaml`).
Las carpetas nativas (`android/`, `ios/`) las genera Flutter:

```bash
cd ibericodex
flutter create . --project-name ibericodex --platforms android,ios
flutter pub get
flutter run                  # probar en un móvil o emulador
flutter build apk --release  # build/app/outputs/flutter-apk/app-release.apk
```

Si `flutter create` genera un `test/widget_test.dart` de ejemplo, bórralo:
hace referencia a una clase `MyApp` que aquí no existe.

## Estructura de carpetas

```
ibericodex/
├── pubspec.yaml
├── assets/
│   ├── data/animals.json        # catálogo (36 especies de partida)
│   └── images/<id>.jpg          # una foto por animal, con el id del JSON
└── lib/
    ├── main.dart                # arranque, tema, proveedor de estado
    ├── models/
    │   ├── animal.dart          # ficha de especie + categorías
    │   └── sighting.dart        # avistamiento: fecha y lugar
    ├── data/
    │   └── animal_repository.dart   # lee el catálogo (JSON hoy, BD/API mañana)
    ├── state/
    │   └── dex_state.dart       # catálogo + registros, persistencia local
    ├── services/
    │   └── identifier_service.dart  # identificación por descripción
    ├── screens/
    │   ├── home_screen.dart         # navegación inferior
    │   ├── dex_grid_screen.dart     # cuadrícula, buscador, filtros
    │   ├── detail_screen.dart       # ficha ampliada + registro
    │   └── field_assistant_screen.dart  # asistente de campo
    └── widgets/
        ├── animal_tile.dart     # miniatura con estado y sello
        ├── animal_image.dart    # foto en gris/color, marcador si falta
        └── register_dialog.dart # diálogo "¿dónde lo has visto?"
```

## Arquitectura

Tres capas, con dependencias en un solo sentido:

- **Datos** (`data/`, `models/`): `AnimalRepository` es el único que sabe de
  dónde sale el catálogo. Cambiar el JSON por SQLite o una API no toca la UI.
- **Estado** (`state/`): `DexState` (ChangeNotifier + provider) guarda el
  catálogo y el mapa de avistamientos, y los persiste con
  `shared_preferences`.
- **Presentación** (`screens/`, `widgets/`): pantallas que observan el estado.

El asistente de campo es un servicio puro (`IdentifierService`), sin
dependencias de UI, así que se puede probar con tests unitarios y sustituir
por otro motor manteniendo la firma `identify(texto, animales)`.

## Modelo de datos

Cada entrada de `assets/data/animals.json`:

```json
{
  "id": "chova_piquirroja",
  "number": 16,
  "commonName": "Chova piquirroja",
  "scientificName": "Pyrrhocorax pyrrhocorax",
  "category": "ave",
  "family": "Corvidae",
  "habitat": "Montañas, cortados fluviales, acantilados...",
  "conservation": "LC",
  "description": "...",
  "facts": ["...", "..."],
  "keywords": ["mediano", "negro", "pico rojo", "patas rojas", "..."]
}
```

- `category`: `mamifero`, `ave`, `reptil`, `anfibio`, `pez`.
- `conservation`: código UICN (`LC`, `NT`, `VU`, `EN`, `CR`).
- `keywords`: rasgos de campo que usa el asistente. Cuanto mejor descritos
  (tamaño, colores, marcas, comportamiento, lugar), mejor identifica.
- La foto se busca en `assets/images/<id>.jpg`.

Avistamiento (guardado en el dispositivo):

```json
{ "animalId": "chova_piquirroja", "date": "2026-11-15T10:30:00", "place": "Hoces del Duratón" }
```

## Cómo funciona el asistente de campo

1. Normaliza el texto: minúsculas, sin tildes, sin plurales ni género.
2. Aplica sinónimos ("pájaro" → ave, "arroyo" → río, "manchas" → moteado).
3. Puntúa cada animal por las palabras que coinciden con su nombre, hábitat
   y `keywords`. Las palabras poco frecuentes en el catálogo pesan más.
4. Si la descripción indica un grupo ("pájaro", "rana", "serpiente"), los
   animales de otros grupos se penalizan.
5. Devuelve los cinco mejores con su porcentaje y un botón para registrar.

Funciona sin conexión, que es lo habitual en el campo.

## Pendiente antes de publicar

- **Fotos**: añadir una imagen por especie con licencia que permita su uso
  y anotar autor y licencia.
- **Estados de conservación**: contrastar cada uno con la Lista Roja de la
  UICN y con el Catálogo Español de Especies Amenazadas; cambian con el
  tiempo y el estado en España puede diferir del global.
- **Catálogo**: ampliar las 36 especies de partida.

## Librerías y APIs recomendadas para crecer

| Necesidad | Opción |
|---|---|
| Estado más escalable | `flutter_riverpod` o `flutter_bloc` |
| Base de datos local | `drift` (SQLite) o `hive` |
| Ubicación del avistamiento | `geolocator` + `geocoding` |
| Mapa de avistamientos | `flutter_map` (OpenStreetMap) |
| Foto propia del avistamiento | `image_picker` |
| Imágenes remotas con caché | `cached_network_image` |
| Navegación con rutas | `go_router` |
| Datos y fotos de especies | API de iNaturalist, API de GBIF, Wikimedia Commons |
| Estados de conservación | API de la Lista Roja de la UICN |
| Asistente con lenguaje natural | Un modelo de lenguaje vía un backend propio (nunca la clave de API dentro de la app) |
| Identificación por foto | `google_mlkit_image_labeling` o un modelo TFLite propio |
