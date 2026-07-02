# 🎮 Proyecto Final: FINAL STAGE

¡Bienvenido al repositorio de FINAL STAGE! Este es un videojuego de plataformas y acción en 2D desarrollado en **Godot Engine 4** como proyecto para el curso de Desarrollo de videojuegos II.

El juego sigue las aventura de **Leo**, quien decidio entrar a la misteriosa torre donde muchos aventureros no puedieron entrar y salir vivos de ahi. **Leo** debe enfrentarse a diversos enemigos como los **Centinelas** (enemigos) y resolver acertijos mediante un sistema de llaves y puertas reutilizables para avanzar a través de los niveles con el proposito de llegar al nivel final y descubrir los secretos de la Torre.

---

## 🚀 Características Principales

* **Sistema de Combate Avanzado:** Control de frames de daño y tiempos de inmunidad arbitrados de forma segura.
* **Inteligencia Artificial (IA):** Enemigos (Centinelas) que patrullan, detectan al jugador, persiguen, atacan y reaccionan al daño de forma dinámica.
* **Mecánicas Reutilizables:** Sistema modular de llaves y puertas parametrizables desde el Inspector de Godot.
* **Diseño Sonoro Integrado:** Efectos de sonido (SFX) para acciones físicas y música de fondo (BGM) persistente entre niveles.

---

## 🏗️ Arquitectura de Software y Patrones de Diseño

Para garantizar un código limpio, mantenible y de bajo acoplamiento, el proyecto se estructuró bajo tres patrones de diseño de software fundamentales:

### 1. Patrón Singleton (Instancia Única)
* **Implementación:** Reflejado en el `CombateManager` (configurado como *Autoload*).
* **Propósito:** Actúa como un árbitro neutral y centralizado para el combate. Controla la tregua de daño de los enemigos hacia Leo y evita el procesamiento duplicado de colisiones en un mismo frame cuando Leo ataca a monstruos amontonados.

### 2. Patrón State (Máquina de Estados Finita)
* **Implementación:** Utilizado en el comportamiento de Leo y la IA de los Centinelas (`enum Estados { PATRULLA, ATACANDO, HERIDO, MUERTO }`).
* **Propósito:** Aísla de forma segura las lógicas de comportamiento. Si una entidad entra en estado de daño o muerte, el sistema bloquea inmediatamente sus funciones de movimiento o ataque, evitando bugs físicos y lógicos.

### 3. Patrón Observer (Observador)
* **Implementación:** Aplicado mediante el sistema de **Señales (Signals)** nativas del motor (como el evento `pressed` de la UI y `body_entered` de las hitboxes) y mediante **Grupos** dinámicos para desacoplar a Leo del HUD.
* **Propósito:** Permite que los scripts se comuniquen sin depender directamente entre sí. Leo solo notifica al grupo `"hud"` que su vida cambió, y la interfaz se actualiza de forma autónoma.

---

## 🛠️ Tecnologías Utilizadas

* **Motor de Videojuegos:** Godot Engine 4.6.1
* **Lenguaje de Programación:** GDScript (Basado en POO)
* **Gráficos:** Pixel Art 2D
* **Formatos de Audio:** `.wav` para efectos de sonido (SFX) y `.mp3`/`.ogg` para música de fondo (BGM).

---

## 💻 Cómo Ejecutar el Proyecto

Si deseas probar el juego desde el entorno de desarrollo, sigue estos pasos:

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/](https://github.com/)[brandy-sinche-dev]/[final-stage].git

2. **Abrir el motor de Godot**
   Una vez abierto el motor tenemos que presionar el boton de importar y nos vamos a la carpeta donde se guardo el repositorio, seleccionaremos el archivo `"project.godot"`
