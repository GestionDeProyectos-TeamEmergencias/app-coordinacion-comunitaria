# Informe de viabilidad

# App de coordinación comunitaria para la **gestión urbana participativa** 

## Gestión de Proyectos.  Primer cuatrimestre 2026

## Grupo D Integrantes :  	Elias Uribe, 	Eric Doyle, 	Lucas Lovizzio, 	Agustin Campagna, 	Tomás Miquelez, 	Joaquín Hubner, 	Jeremías Aguirres

# **Definición del Problema**

## **1\. Contexto**

En diversas ciudades medianas y barrios en desarrollo, existe una brecha de comunicación ineficiente entre los vecinos y las autoridades encargadas del mantenimiento urbano. Los incidentes del espacio público no críticos para la vida humana (tales como baches, luminarias defectuosas, caída de ramas, cables colgando, micro-basurales o calles anegadas) suelen resolverse en tiempos prolongados debido a la falta de un relevamiento ágil y centralizado.

**Cliente Institucional Objetivo:** La solución está diseñada para ser adoptada por **Municipios locales, Comunas o Asociaciones Vecinales (Sociedades de Fomento)**. El organismo gubernamental o barrial asume el rol de administrador y despachador de cuadrillas, mientras que la plataforma se apoya en el concepto de *ciencia ciudadana*, donde la comunidad colabora activamente como una red de sensores urbanos para mapear y visibilizar los problemas de su entorno.

## **2\. El problema central**

La problemática central reside en que los vecinos de localidades medianas y barrios en desarrollo carecen de un canal estructurado y tecnológicamente asistido para reportar y dar seguimiento a problemas del espacio público. Los mecanismos actuales son informales: llamados telefónicos al municipio que frecuentemente no se registran, grupos de WhatsApp sin estructura donde el reporte compite con comunicaciones de todo tipo, o simplemente la resignación ante problemas que permanecen sin atención. Esta informalidad impide que los incidentes sean relevados, priorizados y resueltos de forma eficiente, generando un deterioro progresivo del entorno urbano que afecta la calidad de vida cotidiana de la comunidad. 

Para dar respuesta a esta problemática, se identifica como **Cliente Institucional** primordial a las **Municipalidades y Comunas locales** (tomando como contexto inicial de referencia la ciudad de **Junín, Buenos Aires**). El sistema no funciona de forma aislada, sino como un puente de **Ciencia Ciudadana** donde el municipio asume la administración de los reportes y la validación de los mismos para la asignación de sus cuadrillas de mantenimiento urbano.

## **3\. Actores afectados**

Esta situación impacta directamente sobre tres grupos de actores. En primer lugar, los **vecinos** que detectan problemas en el espacio público y no cuentan con un canal dedicado, ágil y confiable para reportarlos y hacer seguimiento de su resolución. En segundo lugar, los **referentes/voluntarios barriales o inspectores comunitarios** que podrían coordinar y verificar los reportes en su zona pero no reciben información geolocalizada ni estructurada para hacerlo eficientemente. Finalmente, los **administradores municipales o vecinales** que carecen de herramientas para recibir, priorizar y gestionar los reportes de incidentes de forma centralizada y auditable. 

## **4\. Insuficiencia de los mecanismos actuales**

Los mecanismos informales de comunicación comunitaria vigentes adolecen de cuatro fallas estructurales. Primero, **ausencia de priorización automática**: no existe ningún proceso que clasifique la urgencia de un incidente urbano de forma sistemática, quedando dicha evaluación librada al criterio subjetivo de cada participante del canal, sin distinción entre un cable eléctrico expuesto y un bache menor. Segundo, **falta de geolocalización operativa**: no existe forma de identificar automáticamente la ubicación exacta del problema ni qué referentes o recursos se encuentran en un radio de acción útil, impidiendo una respuesta territorial eficiente. Tercero, **informalidad del canal**: la dependencia de aplicaciones de propósito general implica que no existe verificación de reportes, moderación de denuncias duplicadas ni registro auditable de los incidentes atendidos, lo que compromete la confiabilidad del sistema. Cuarto, **inaccesibilidad situacional**: estos canales requieren interacción manual completa, dificultando el reporte en situaciones donde el vecino está en movimiento, conduce o necesita mantener las manos libres. 

## **5\. Consecuencias de no resolver el problema**

La persistencia de este vacío tiene consecuencias directas sobre la calidad del espacio público y la seguridad comunitaria. Los problemas urbanos no reportados o reportados tardíamente escalan en gravedad y costo de reparación: un bache sin atención daña vehículos, una luminaria defectuosa favorece la inseguridad nocturna, un cable colgante representa un riesgo eléctrico creciente. Los referentes barriales y administradores municipales no cuentan con información estructurada para priorizar intervenciones, subutilizando los recursos disponibles. La ausencia de trazabilidad impide además evaluar la eficiencia de la gestión urbana, dificultando la rendición de cuentas ante la comunidad. 

# **Alcance del Producto**

El producto a desarrollar consiste en una aplicación móvil multiplataforma (compatible con los sistemas operativos Android e iOS) orientada al relevamiento, clasificación y seguimiento de incidentes urbanos a nivel comunitario .  
El alcance de la aplicación comprende el desarrollo de las siguientes funcionalidades principales:

* **Gestión de usuarios y roles:** Registro, autenticación y administración de perfiles bajo tres roles claramente diferenciados:  
  * **Vecinos informantes:** Usuarios base con capacidad para emitir/reportar incidentes urbanos  (vía interfaz gráfica o comandos de voz) y proveer contexto inicial del incidente.

  * **Referentes barriales:** Usuarios verificados habilitados para recibir alertas push categorizadas, visualizar la geolocalización de los incidentes reportados en su zona y confirmar la verificación del problema en el lugar. 

  * **Administradores del sistema:** Personal encargado de moderar la plataforma, gestionar las altas/bajas de voluntarios, auditar reportes falsos y calibrar las variables del motor de priorización.

* **Reporte de incidentes híbrido:** Capacidad de emitir alertas de problemas en el espacio público mediante una interfaz gráfica tradicional (formularios y botones de reporte rápido ) y mediante interfaces no tradicionales basadas en el procesamiento de comandos vocales (transcripción y procesamiento de lenguaje natural) para situaciones donde el uso manual del dispositivo se vea dificultado.

* **Motor de priorización:** Implementación de un algoritmo interno que clasifique y asigne un nivel de criticidad a cada incidente reportado de manera automática, basándose en palabras clave y categorizaciones predefinidas.

* **Geolocalización en tiempo real:** Mapeo del origen de la alerta y rastreo de la ubicación de los usuarios registrados como voluntarios para identificar a aquellos que se encuentren en un radio de proximidad operativo.

* **Sistema de alertas push:** Emisión de notificaciones focalizadas a los voluntarios cercanos seleccionados por el sistema, detallando el nivel de prioridad y la ubicación exacta del incidente.

## **Límites del alcance (Fuera del alcance):**

Para evitar ambigüedades, se establece explícitamente que el producto **no** sustituye a los servicios de emergencia oficiales (911, Policía, Bomberos, Ambulancias), sino que actúa como una red de relevamiento y seguimiento comunitario de incidentes urbanos . Asimismo, el proyecto no incluye la provisión de hardware (dispositivos móviles) ni planes de conectividad a internet para los usuarios, recayendo la ejecución del software sobre los dispositivos personales de cada ciudadano. 

# **Competidores**

Se han identificado soluciones que operan en el territorio nacional, analizando sus limitaciones frente a la solución propuesta:

* ### SAC (Sistema de Alerta Comunitaria) y Seguridad MI:

  Son sistemas "Estado-céntricos" que dependen de un operador humano municipal. La aplicación propuesta permite la auto-organización mediante voluntarios verificados en un radio operativo de proximidad. 

* ### Vigila App & IBIS SOS:

  Presentan entrada de datos puramente manual, deficiente bajo alto estrés. El sistema propuesto incorpora NLP (Procesamiento de Lenguaje Natural) para reportes manos libres, complementando la interfaz tradicional.

* ### Responder:

  Orientada exclusivamente a profesionales. No integra al ciudadano común. La solución desarrollada gestiona brigadas para vecinos capacitados mediante una gestión de roles diferenciados. 

* ### Noggin (Resilience Software): 

  Es el estándar corporativo global, excluido del uso comunitario por su complejidad y costo. La propuesta simplifica esta lógica para el usuario final.

* ### BA 147 (CABA): 

  Aplicación oficial de la Ciudad de Buenos Aires para reclamos urbanos ([buenosaires.gob.ar/147](https://www.google.com/search?q=https://buenosaires.gob.ar/147)). Su límite es su exclusividad geográfica y rigidez en la carga.

* ### SeeClickFix: 

  Plataforma global líder en reporte ciudadano para municipios ([seeclickfix.com](https://seeclickfix.com/)). Su costo y falta de localización en Argentina dificultan su adopción en ciudades medianas.

* ### MuniDigital: 

  Sistema de gestión municipal utilizado en varias localidades del país ([munidigital.com](https://munidigital.com/)). Se centra más en la gestión interna que en la experiencia comunitaria con IA.

## **Comparativa con Competidores:**

| Competidor | Limitación principal | Diferenciador de la propuesta |
| ----- | ----- | ----- |
| SAC / Seguridad MI | Dependencia de operador humano municipal | Auto-organización comunitaria sin intermediario estatal |
| Vigila App / IBIS SOS | Entrada de datos exclusivamente manual | Interfaz híbrida con NLP para reporte por voz |
| Responder | Orientada solo a profesionales | Integra al ciudadano común mediante gestión de roles |
| Noggin | Complejidad y costo corporativo elevado | Diseño simplificado orientado al usuario final comunitario |
| BA 147  | Exclusividad geográfica CABA, interfaz rígida sin NLP  | Adaptable a cualquier municipio, con reporte por voz e inteligencia de clasificación  |
| SeeClickFix  | Costo elevado y sin localización en Argentina  | Diseño local, accesible para municipios de escala media sin licencias costosas  |
| MuniDigital  | Orientado a gestión interna municipal, sin participación activa del ciudadano  | Foco en el vecino como actor central del relevamiento mediante ciencia ciudadana  |

## **Ventajas Competitivas:**

A diferencia de los competidores, el sistema propuesto presenta las siguientes ventajas:

* **Reducir la fatiga de alertas:**   
  A diferencia de los grupos de WhatsApp o apps básicas que notifican a todos por igual, el sistema filtra y envía alertas exclusivamente a los voluntarios cercanos al incidente.  
* **Accesibilidad crítica (NLP):**  
  El reporte híbrido permite que una persona en movimiento, conduciendo o con las manos ocupadas , con movilidad reducida o que necesita mantener las manos libres, pueda realizar el reporte de forma ágil sin interrumpir su actividad   
* **Clasificación automática de incidentes:**    
  El sistema asigna un nivel de prioridad a cada reporte mediante el análisis de palabras clave en la descripción del incidente, permitiendo que los referentes barriales y administradores atiendan primero los problemas de mayor urgencia relativa. 

# **Identificación de Riesgos**

## **Riesgos Técnicos**

* **Fallas en la geolocalización:** Error en la precisión de las coordenadas (el voluntario va a la calle incorrecta).  
* **Saturación del Servidor:** Muchos reportes simultáneos durante una catástrofe natural real.  
* **Latencia en Alertas:** Que las notificaciones push lleguen 5 minutos tarde.

## **Riesgos Operativos / Externos**

* **Reportes Falsos (Trolls):** Saturación del sistema con incidentes inexistentes que agotan a los voluntarios.  
* **Baja Adopción:** Que los vecinos no descarguen la app, haciendo que el sistema de cercanía no funcione.  
* **Responsabilidad Civil:** Problemas legales derivados de intervenciones de referentes barriales en incidentes que escalan a situaciones de riesgo no previstas 

## **Riesgos de Gestión de Proyecto**

* **Subestimación del Algoritmo:** Que la lógica de priorización sea más compleja de programar de lo previsto.  
* **Falta de Datos Reales:** Dificultad para testear el algoritmo sin incidentes urbanos reales disponibles para validación .

## **Matriz de Probabilidad e Impacto:**

| Riesgo | Probabilidad (P) | Impacto (I) | P x I (Prioridad) | Estrategia de Mitigación |
| :---: | :---: | :---: | :---: | :---: |
| **Reportes falsos constantes** | 4 | 4 | 16 (Muy Alto) | Sistema de reputación de usuarios, verificación de voluntarios y moderación centralizada por administradores. |
| **Caída del servidor ante alta demanda de reportes**  | 2 | 5 | 10 (Alto) | Diseño de arquitectura escalable desde la fase inicial, con balanceo de carga. |
| **Latencia en alertas push** | 3 | 4 | 12 (Alto) | Uso de servicios de notificaciones con SLA garantizado (FCM/APNs). |
| **Baja adopción comunitaria** | 4 | 3 | 12 (Alto) | Estrategia de despliegue local para asegurar masa crítica mínima antes del lanzamiento. |
| **Error en precisión de geolocalización** | 3 | 3 | 9 (Medio) | Calibración con múltiples fuentes GPS y validación cruzada con dirección ingresada. |
| **Responsabilidad civil por lesiones** | 2 | 4 | 8 (Medio) | Términos y condiciones claros que delimiten la responsabilidad de la plataforma. |
| **Subestimación del algoritmo** | 2 | 4 | 8 (Medio) | Integración de APIs de NLP pre-entrenadas para reducir la complejidad de desarrollo. |
| **Falta de datos reales para testeo** | 3 | 3 | 9(Medio) | Simulación de escenarios de incidentes urbanos  mediante datos sintéticos y pruebas controladas con el equipo durante la etapa de desarrollo |

# **Justificación de la Solución y Evidencias de Viabilidad**

El desarrollo de esta plataforma se fundamenta en la necesidad documentada de reducir la brecha informativa entre la ocurrencia de un problema urbano y su atención por parte de las autoridades competentes. La literatura académica sobre ciencia ciudadana aplicada al desarrollo urbano sustentable señala que estas plataformas generan beneficios concretos para organizaciones públicas y la comunidad en conjunto, al distribuir la capacidad de relevamiento entre los propios vecinos en lugar de depender exclusivamente de inspecciones municipales programadas (Cappa et al., 2022). Casos de implementación documentados, como el de la ciudad de Gilbert (Arizona), demuestran que este modelo mejora los tiempos de respuesta municipal y aumenta la transparencia en la resolución de incidentes urbanos (SeeClickFix / CivicPlus, 2023). La demora en el reporte de incidentes como cables eléctricos expuestos, tapas de alcantarilla faltantes o luminarias defectuosas incrementa progresivamente el riesgo de accidentes y el costo de reparación, fundamentando la necesidad de una red comunitaria que reduzca esa latencia informativa.

A nivel de mercado y ventajas competitivas, la arquitectura del sistema resuelve deficiencias comprobadas en otras aplicaciones. En primer lugar, aborda la "fatiga de alertas" (Alert Fatigue), un fenómeno psicológico y técnico por el cual la sobreexposición a notificaciones irrelevantes disminuye la capacidad de respuesta, llegando a tasas de desensibilización superiores al 80% (Joint Commission; MDPI, 2025). Al incorporar algoritmos de geolocalización, el sistema notifica únicamente a los referentes barriales operativos en el radio del incidente, mitigando este riesgo.

En segundo lugar, frente a soluciones que exigen el llenado de formularios, la plataforma implementa una interfaz de entrada híbrida asistida por Procesamiento de Lenguaje Natural (NLP). Investigaciones recientes sobre NLP aplicado a la clasificación automática de reclamos ciudadanos demuestran que estos modelos pueden categorizar incidentes urbanos por tipo y nivel de urgencia a partir de descripciones en lenguaje natural, reduciendo significativamente la carga manual sobre los administradores del sistema (Vani & Ashwitha, 2025).

 

# 

# **Conclusión de Viabilidad**

## **1\. Justificación Estratégica (Necesidad del Problema)**

La brecha de comunicación entre el vecino y el municipio genera un deterioro visible del espacio público. La transición de la app hacia un modelo de **Ciencia Ciudadana** permite que el ciudadano se convierta en un sensor activo, mejorando la eficiencia en la detección de problemas no críticos que afectan la calidad de vida diaria.

## **2\. Factibilidad Técnica y Funcional**

El alcance definido demuestra una comprensión madura del desafío. La integración de tres pilares tecnológicos permite superar las limitaciones de las soluciones actuales:

**Interfaz Híbrida:** Elimina la fricción de la interacción manual bajo estrés, permitiendo el reporte mediante voz, lo cual es crítico para usuarios en situación de incapacidad física.

**Motor de Priorización:** Resuelve la saturación informativa al automatizar la clasificación de incidentes  (priorizar por prioridad y no por orden de llegada), asegurando que los voluntarios reciban únicamente alertas relevantes.

**Geolocalización Operativa:**Optimiza la identificación y seguimiento de incidentes por zona, facilitando la coordinación entre referentes barriales .

## **3\. Ventaja Competitiva frente al Mercado**

A diferencia de las apps de reporte tradicionales, la solución propuesta prioriza la auto-organización comunitaria y la facilidad de uso mediante comandos de voz , lo que reduce la fricción en el reporte y asegura una base de datos más rica y precisa para el administrador municipal.

## 

## **4\. Evaluación de Riesgos y Mitigación**

El principal riesgo identificado es la confusión con servicios de emergencia crítica. Esto se mitiga mediante un **flujo de advertencia obligatorio (disclaimer)** y una IA configurada para detectar palabras clave de alta criticidad, derivando automáticamente al usuario a los números oficiales (911/107) en caso de detectar un riesgo de vida.

## **5\. Dictamen Final**

Se concluye que el proyecto es **altamente viable** bajo el nuevo enfoque de incidentes no críticos. La reducción de la criticidad del dominio elimina barreras legales operativas complejas, permitiendo una implementación segura y eficiente que aporta un valor real tanto al ciudadano como a la administración pública municipal.

# Referencias

- **Infobrisas (7 de abril de 2026).** *Diego García propone una nueva aplicación de emergencias*. [https://www.infobrisas.com/noticias/2026/04/07/91913-diego-garcia-propone-una-nueva-aplicacion-de-emergencias](https://www.infobrisas.com/noticias/2026/04/07/91913-diego-garcia-propone-una-nueva-aplicacion-de-emergencias)  
- **La Nación (28 de marzo de 2026).** *Los municipios buscan sumar tecnología para facilitar la participación de vecinos en la prevención del delito*. [https://www.lanacion.com.ar/seguridad/los-municipios-buscan-sumar-tecnologia-para-facilitar-la-participacion-de-vecinos-en-la-prevencion-nid28032026/](https://www.lanacion.com.ar/seguridad/los-municipios-buscan-sumar-tecnologia-para-facilitar-la-participacion-de-vecinos-en-la-prevencion-nid28032026/)  
- **Municipalidad de Córdoba (12 de octubre de 2024).** *Para enfrentar tormentas fuertes y situaciones relacionadas al clima, la Municipalidad de Córdoba conformó 50 comités de Emergencia Barrial*. [https://cordoba.gob.ar/creacion-50-comites-emergencia-barrial/](https://cordoba.gob.ar/creacion-50-comites-emergencia-barrial/)  
- **The Joint Commission / MDPI (2025).** *The Effect of Alarm Fatigue on the Tendency to Make Medical Errors*. Healthcare Safety Studies. Análisis sobre la desensibilización de usuarios ante alertas masivas y la necesidad de priorización.  
- Cappa, F. et al. (2022). *Citizens and cities: Leveraging citizen science and big data for sustainable urban development*. Business Strategy and the Environment, 31(2), 648-667. [https://ideas.repec.org/a/bla/bstrat/v31y2022i2p648-667.html](https://ideas.repec.org/a/bla/bstrat/v31y2022i2p648-667.html)   
- Vani, K. & Ashwitha, C. (2025). *Smart Civic Complaint Analyzer Using Natural Language Processing*. International Journal of Innovative Research in Technology (IJIRT), 12(6), 5408-5415. [https://ijirt.org/article?manuscript=187517](https://ijirt.org/article?manuscript=187517)   
- SeeClickFix / CivicPlus (2023). *Gilbert, AZ Transformed Pothole Reporting for Safer Roads*. The Atlas. [https://the-atlas.com/projects/gilbert-arizona-311-pothole-reporting](https://the-atlas.com/projects/gilbert-arizona-311-pothole-reporting) 

