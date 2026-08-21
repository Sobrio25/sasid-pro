# 🏢 Espectra CDMX (SASID Flutter)

> **Generador y visualizador de espectros de diseño sísmico para la Ciudad de México** basado en las **Normas Técnicas Complementarias para Diseño por Sismo (NTC-CDMX 2017 / 2023 y 2004)**.

Desarrollado en **Flutter**, es una alternativa moderna, multiplataforma (Windows, Web, Android, iOS) y de código abierto al clásico **SASID A**.

---

## 🌟 Características Principales

* 🗺️ **Mapa Interactivo CDMX (GIS):**
  * Selección de puntos por clic o arrastre de marcador en cualquier zona del Valle de México.
  * Capas visuales de zonificación geotécnica: **Zona I (Lomas)**, **Zona II (Transición)** y **Zona III (Lago)**.
  * Búsqueda inteligente de direcciones (Alcaldía, Colonia, Calle, CP) con OpenStreetMap Nominatim.
  * Catálogo de sitios de referencia predefinidos (Zócalo, CU UNAM, Santa Fe, Paseo de la Reforma, Polanco, Roma/Condesa, AICM, etc.).

* ⚙️ **Motor de Cálculo Espectral (NTC-CDMX):**
  * Determinación automática de parámetros del sitio: Periodo del suelo ($T_s$), aceleración máxima ($a_0$), coeficiente sísmico ($c$), periodos de meseta ($T_a, T_b$) y exponente de caída ($k$).
  * Factores estructurales configurables: Grupo de Importancia ($A, B, A1$), Factor de Comportamiento Sísmico ($Q = 1.0, 1.5, 2.0, 3.0, 4.0$), Factor de Irregularidad ($lpha = 1.0, 0.9, 0.8, 0.7$) y Factor de Hiperestaticidad ($k_1$).
  * Cálculo del factor de sobrerresistencia base ($R_0$) y reducción inelástica dependiente del periodo ($Q'(T)$ y $R(T)$).
  * Espectro Elástico transparente vs Espectro Inelástico de Diseño.
  * **Espectro de Peligro Uniforme (EPU)**.
  * **Modo Comparación Multicriterio:** Comparación contra **NTC-2004** (Cuerpo principal y Apéndice A) para variaciones de $Q$.

* 📈 **Visualización y Gráficas de Alta Fidelidad:**
  * Gráfica 2D interactiva con cursor/tooltip en tiempo real para consultar $S_a(T)$ en cualquier periodo $T$.
  * Sub-gráficas comparativas simultáneas para $Q = 1.5, 2.0, 3.0, 4.0$.
  * Tabla de valores tabulados $(T, S_a)$ de $0.0\,\text{s}$ a $5.0\,\text{s}$ con copiado directo al portapapeles.

* 💾 **Exportación para Ingeniería Estructural:**
  * 📄 **Memoria de Cálculo en PDF:** Documento formal con resumen técnico, zonificación, factores y tabla espectral.
  * 💻 **Archivo .TXT para SAP2000 y ETABS:** Formato estándar listo para importar en software de análisis estructural con encabezados de comentarios `$`.
  * 📊 **Archivo .CSV para Excel:** Datos tabulados con parámetros del sitio.

---

## 📐 Fundamento Teórico y Normativo

El cálculo de las ordenadas espectrales $a(T)$ y su reducción inelástica sigue las expresiones del **Apéndice A** de las Normas Técnicas Complementarias para Diseño por Sismo del Reglamento de Construcciones de la Ciudad de México:

$$
a_e(T) = 
\begin{cases} 
a_0 + (c - a_0) \frac{T}{T_a} & \text{si } T < T_a \\[6pt]
c & \text{si } T_a \leq T \leq T_b \\[6pt]
c \left(\frac{T_b}{T}\right)^k & \text{si } T > T_b 
\end{cases}
$$

El espectro inelástico de diseño reducido se obtiene como:

$$
a_d(T) = \max \left( \frac{I \cdot a_e(T)}{Q'(T) \cdot R(T) \cdot \alpha}, \; \frac{a_0 \cdot I}{2 \cdot R_0 \cdot \alpha} \right)
$$

---

## 🚀 Instalación y Ejecución

### Prerrequisitos
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión 3.20 o superior).
* Git.

### Pasos

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/Sobrio25/espectra-cdmx.git
   cd espectra-cdmx
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar en la plataforma deseada:**
   ```bash
   # Windows Desktop
   flutter run -d windows

   # Navegador Web (Chrome)
   flutter run -d chrome

   # Dispositivo móvil Android / iOS
   flutter run
   ```

---

## 🧪 Pruebas Unitarias

Para ejecutar la suite de pruebas del motor sísmico y la interfaz:

```bash
flutter test
```

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.
