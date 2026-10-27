# AdGuard en toda la red: hallazgos y guía de diagnóstico

Caso observado el **27 de octubre de 2026**. Este documento resume las
evidencias, los criterios de diagnóstico y las comprobaciones reutilizables.
Los resultados describen esta sesión, no un monitoreo permanente.

## Resultado y contexto

AdGuard respondía y filtraba correctamente, pero la laptop también recibía el
router como servidor DNS. Cuando lo utilizaba, las consultas evitaban el filtrado.
Después de configurar la IP de AdGuard en ambos campos DNS del DHCP del router,
la comprobación final mostró únicamente esa IP y todas las pruebas pasaron.

| Componente | Valor observado |
|---|---|
| Router | TP-Link Archer C7 v5.0, firmware 1.2.1, según su propietario |
| Router / puerta de enlace | `192.168.0.1` |
| Servidor AdGuard | `qbismo`, `192.168.0.122` |
| Instalación | Contenedor Docker `adguard`, imagen `adguard/adguardhome` |
| DNS publicado | Puerto 53, UDP y TCP, en `192.168.0.122` |
| Panel de AdGuard | `http://192.168.0.122:4444` |
| Laptop | `omar`, Omarchy, conexión `mega-1`, interfaz `wlp195s0` |
| Gestión de DNS | NetworkManager y systemd-resolved |
| DHCP | En el router; desactivado en AdGuard |

La verificación quedó disponible mediante `just test-adguard`, definido en el
[Justfile](../Justfile), y en el
[script de diagnóstico](../scripts/system/test-adguard.sh).

## Conceptos necesarios

| Concepto | Función | Qué conviene comprobar |
|---|---|---|
| DHCP | Entrega al cliente su configuración de red, incluidos los DNS | Qué opciones recibió realmente el cliente |
| DNS | Resuelve nombres como `example.com` | A qué servidor llega la consulta y qué responde |
| Puerta de enlace | Permite llegar a otras redes | No confundir su dirección con el DNS que queremos usar |
| NetworkManager | Gestiona conexiones y recibe sus parámetros | Perfil guardado y datos efectivos de la interfaz |
| systemd-resolved | Resuelve y mantiene caché de consultas del sistema | Servidor seleccionado y configuración por interfaz |
| AdGuard Home | Aplica reglas a las consultas DNS que recibe | Respuesta directa, filtros y registro de consultas |

En esta instalación, `/etc/resolv.conf` apuntaba al stub de systemd-resolved y
mostraba `127.0.0.53`. Esa dirección es el intermediario local; para conocer el
servidor de salida había que consultar `resolvectl status`.
[Referencia de systemd-resolved](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html).

Para las aplicaciones que utilizan el DNS del sistema, la ruta relevante era:

```text
Configuración: router DHCP → NetworkManager → systemd-resolved

Consulta: aplicación → 127.0.0.53 → servidor DNS seleccionado
                                   ├─ 192.168.0.122: filtraba
                                   └─ 192.168.0.1: no filtraba
```

AdGuard no necesita convertirse en la puerta de enlace: atiende consultas DNS.
La puerta de enlace puede seguir siendo `192.168.0.1` mientras el DNS es
`192.168.0.122`.

### Primario y secundario no garantizan prioridad estricta

systemd-resolved puede cambiar de servidor después de un error y continuar
utilizando el siguiente. Por eso, anunciar un servidor filtrado y otro sin
filtrado permite resultados diferentes según el servidor seleccionado.
[Comportamiento documentado](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html).

La lista recibida y el servidor seleccionado son datos distintos. Que AdGuard
aparezca primero no demuestra que la consulta actual lo utilice.

## Evidencias y decisiones de diagnóstico

| Observación | Conclusión respaldada | Límite de esa conclusión |
|---|---|---|
| `dig @192.168.0.122 doubleclick.net A` devolvía `0.0.0.0` | AdGuard era accesible y bloqueaba ese dominio desde la laptop | No demuestra que las aplicaciones lo usaran |
| La misma consulta a `.1` devolvía una IP pública | El DNS del router permitía ese dominio | No identifica cuál era su servidor DNS ascendente |
| La consulta por defecto coincidía con `.1` y `resolvectl` lo mostraba seleccionado | La ruta DNS del sistema estaba evitando AdGuard en ese momento | No identifica qué error provocó el cambio de servidor |
| NetworkManager mostraba `domain_name_servers = 192.168.0.122 192.168.0.1` | El cliente tenía ambos DNS en las opciones DHCP recibidas | No se capturaron paquetes DHCP ni se auditó el firmware |
| El perfil no tenía DNS manual y aceptaba los automáticos | No había un DNS manual en ese perfil que explicara `.1` | Otros perfiles, VPN o aplicaciones pueden tener sus propios ajustes |
| La renovación de las 11:11 volvió a mostrar ambos DNS | El problema persistía después de una renovación anterior al cambio final | Esa renovación no probaba el resultado de un cambio posterior |
| En la prueba final solo figuraba `.122`; bloqueo y resolución normal pasaron | El ajuste final funcionaba para la conexión probada | No equivale a probar todos los dispositivos de la casa |

También se comprobó resolución normal directamente contra AdGuard y bloqueo
por TCP, además de UDP. Esto descartaba una caída total del servicio o un
bloqueo total del puerto 53 desde esa laptop durante las pruebas.

Tailscale estaba detenido en el cliente. No estaba proporcionando un DNS activo
que explicara este caso; tampoco era necesario para consultar AdGuard por la LAN.

El registro de systemd-resolved contenía una degradación de funciones EDNS para
`.122`. Es una pista de compatibilidad o comunicación, pero **no demuestra por sí
sola por qué terminó seleccionado `.1`**.

## Qué cambió y qué sigue siendo una hipótesis

El propietario confirmó que el panel ya tenía AdGuard como DNS primario y el
secundario vacío. Mi propuesta inicial de dejarlo vacío repetía el estado
existente: faltaba explicar la discrepancia entre el panel y los DNS recibidos.

La prueba aplicada en **Advanced → Network → DHCP Server** fue:

| Campo | Valor final comunicado |
|---|---|
| Primary DNS | `192.168.0.122` |
| Secondary DNS | `192.168.0.122` |
| Default Gateway | `192.168.0.1` |

La ubicación de esos ajustes está documentada en la
[guía del Archer C7 v5](https://www.tp-link.com/us/user-guides/Archer-C7/chapter-13-customize-your-network-settings).
La combinación concreta de DNS repetido se validó mediante las pruebas de esta
sesión; no se presenta como una garantía del fabricante para cualquier firmware.

Después de guardar el cambio aún se observó la misma concesión anterior con
ambos DNS. En una comprobación posterior solo apareció `.122` y el script terminó
con código `0`. No se registró el instante exacto de adquisición de esa nueva
configuración.

Los resultados son compatibles con que el router incorporase su propia IP
cuando el segundo campo estaba vacío. **El mecanismo interno queda como
hipótesis**: no se inspeccionó el backend del firmware ni se hizo una prueba
controlada de volver al campo vacío y comparar otra vez.

Repetir una IP no crea un segundo servidor ni aporta redundancia. Si `qbismo`
deja de atender DNS, las dos entradas dependen del mismo servicio. Para disponer
de redundancia real habría que tener otro servidor filtrado accesible.

## Procedimiento para diagnosticar una recurrencia

### 1. Identificar la conexión y observar lo recibido

```bash
nmcli -f NAME,TYPE,DEVICE connection show --active
nmcli -f IP4.DNS,IP6.DNS,DHCP4.OPTION device show wlp195s0
resolvectl status
```

Examinar los campos `domain_name_servers`, `DNS Servers` y `Current DNS Server`.
Que `.1` aparezca como `routers` o `dhcp_server_identifier` es normal: el problema
era que aparecía **también como servidor DNS**.

`resolvectl status` sin limitar la interfaz ayuda a detectar otros enlaces o VPN.
La lista global `Fallback DNS Servers` no significa que esos servidores estén
atendiendo consultas: se utiliza cuando no hay otra información DNS disponible.
[Referencia de resolved.conf](https://www.freedesktop.org/software/systemd/man/latest/resolved.conf.html).

### 2. Comparar la misma consulta por tres rutas

```bash
dig +time=3 +tries=1 @192.168.0.122 doubleclick.net A
dig +time=3 +tries=1 @192.168.0.1 doubleclick.net A
dig +time=3 +tries=1 doubleclick.net A
```

Mantener el dominio y el tipo de registro iguales permite atribuir diferencias
al camino consultado. La consulta con `@servidor` prueba ese servidor; la consulta
sin `@` prueba el camino configurado para `dig` en el sistema.

Si AdGuard directo bloquea y el camino del sistema no, revisar selección de DNS,
configuración de otros enlaces y caché antes de modificar las listas de bloqueo.
Si AdGuard directo tampoco bloquea, revisar sus filtros, excepciones y registro.
[Diagnóstico oficial de AdGuard](https://adguard-dns.io/kb/adguard-home/faq/).

### 3. Comprobar que bloquear no significa haber roto DNS

```bash
dig +time=3 +tries=1 @192.168.0.122 example.com A
dig +time=3 +tries=1 example.com A
dig +time=3 +tries=1 @192.168.0.122 doubleclick.net AAAA
dig +tcp +time=3 +tries=1 @192.168.0.122 doubleclick.net A
```

En esta configuración se esperaba `0.0.0.0` para el registro A bloqueado y `::`
para el AAAA bloqueado. Un dominio permitido debía devolver direcciones normales.
Las IP concretas de un dominio público pueden cambiar; no deben fijarse como
resultado esperado.

Un registro AAAA contiene una dirección IPv6, pero puede consultarse a un
servidor IPv4. Esta prueba **no verifica transporte DNS sobre IPv6**.

### 4. Distinguir una concesión antigua de una respuesta en caché

```bash
journalctl -b -u NetworkManager --no-pager -g 'dhcp4.*new lease'
journalctl -b -u systemd-resolved --no-pager -n 80
```

Comparar la hora de renovación y el campo DHCP `expiry` con el momento del
cambio del router. Una concesión anterior al cambio no permite evaluar todavía
lo que el router entregará después.

Para aplicar ajustes DHCP nuevos, reconectar el Wi-Fi y volver a inspeccionar
las opciones recibidas. Esto puede interrumpir conexiones abiertas; no lo hace
el script de diagnóstico.

Si la lista DNS ya es correcta pero una respuesta antigua persiste, se puede
limpiar explícitamente la caché del sistema y repetir la consulta:

```bash
sudo resolvectl flush-caches
```

Limpiar esa caché no renueva DHCP ni limpia necesariamente la caché del navegador.
Guardar el panel, renovar la concesión y comprobar una consulta son pasos
distintos; hay que verificar cada uno cuando el resultado no coincide.

### 5. Ejecutar la comprobación reproducible

Desde la raíz del repositorio:

```bash
just test-adguard

# Para otra interfaz o dirección del servidor:
just test-adguard eth0 192.168.0.122

# Invocación directa equivalente:
bash scripts/system/test-adguard.sh wlp195s0 192.168.0.122
```

El script requiere Bash, NetworkManager (`nmcli`), `dig` y `grep`. No instala
dependencias ni renueva DHCP; tampoco cambia ajustes o limpia cachés. Su código de salida
es `0` si pasan las comprobaciones, `1` si alguna falla y `2` si falta una
dependencia o no puede consultar la interfaz.

Durante su desarrollo se detectó que `nmcli -g` agrupaba varios DNS con ` | ` en
este equipo. El script utiliza salida con nombres de campo e interpreta cada
entrada `IP4.DNS` o `IP6.DNS` por separado. Es un recordatorio de comprobar el
formato real de una herramienta antes de automatizar su interpretación.

## Límites del script y comprobaciones adicionales

- Valida los DNS de la interfaz indicada y algunas consultas del sistema; no
  audita todas las rutas DNS de otros enlaces o VPN.
- Espera el modo de bloqueo observado (`0.0.0.0` y `::`). Un cambio legítimo de
  política, dominio de prueba o lista puede exigir actualizar esas expectativas.
- Las consultas por defecto pueden usar caché. Un bloqueo aislado no prueba que
  la configuración sea correcta; por eso también se comprueba la lista DNS.
- No demuestra el comportamiento del navegador ni de todos los equipos. Un
  navegador con DNS cifrado propio, DNS privado manual o una VPN puede utilizar
  otro camino. Revisar sus ajustes y correlacionar una consulta nueva con el
  registro de AdGuard. Una respuesta en caché puede no generar una entrada nueva.
- No se probó persistencia después de reiniciar el router o `qbismo`. El
  contenedor tenía política `unless-stopped`; eso no sustituye probar un reinicio
  ni comprobar que el servidor conserve su dirección IP.

Para validar la cobertura de la casa, renovar la conexión de otro equipo con DNS
automático y observar sus consultas en AdGuard. La configuración central no
equivale a impedir que un dispositivo elija un DNS distinto.

## Correcciones y aprendizajes

- **La objeción al primer plan era válida.** El secundario ya estaba vacío;
  había que contrastar lo guardado con el estado efectivo del cliente.
- **Instalar AdGuard no dirige las consultas hacia él.** El cliente necesita
  recibirlo y utilizarlo como DNS. El router permite distribuirlo por DHCP.
  [Configuración centralizada de AdGuard](https://adguard-dns.io/kb/adguard-home/getting-started/#router).
- **Un DNS sin filtrado como alternativa permite evitar el bloqueo.** No se
  debe interpretar la etiqueta «secundario» como una garantía de último recurso.
- **Un servidor saludable no demuestra un camino correcto.** Hay que comparar
  la respuesta directa con la del sistema.
- **Un resultado inicial fallido después de guardar no prueba que el cambio
  haya fallado.** Primero comprobar si el cliente recibió una concesión nueva.
- **El alcance pedido importa.** Forzar DNS en la laptop podía servir como
  prueba aislada, pero no resolvía el objetivo de configurar toda la red.
- **Una prueba exitosa tiene límites.** Aquí respalda la corrección en la
  conexión probada; no autoriza afirmar que se bloquean todos los anuncios,
  todos los dispositivos o cualquier DNS cifrado.

La práctica reutilizable es registrar **configuración deseada, configuración
recibida, servidor seleccionado y respuesta observada**. Cambiar una variable
por vez y repetir la misma consulta permite comparar resultados sin atribuir
al servidor un problema que pertenece al camino usado para llegar a él.
