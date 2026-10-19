#import "@preview/splash:0.5.0": tol-light
#let permit = table.cell(fill: tol-light.mint)[Permitido]
#let block = table.cell(fill: tol-light.pink)[Bloqueado]
#let block_by_defect = table.cell(fill: tol-light.pink)[Bloqueado\*]
#let limited = table.cell(fill: tol-light.light-yellow )[Limitado]
#let na = table.cell(fill: tol-light.pale-grey)[-] // Para conexiones consigo mismo


= Trabajo final integrador - Infraestructura

== 1.

Diagrama de la topología implementada:

#image("diagrama_infra.png")

Para este diagrama fijé las ips de las vms LAN, ADMIN, SERV_A y SERV_B, ya que previamente se asignaban por dhcp.

== 2.
#align(center)[
  #table(
    columns: 2, 
    [*Lugar*], [*Dirección IP*],
    [Interfaz WAN],[10.41.107.172],
    [Interfaz LAN],[192.168.10.1],
    [Interfaz ADMINISTRACION],[192.168.30.1],
    [Interfaz SERVIDORESA],[192.168.20.1],
    [Interfaz SERVIDORESB],[44.0.51.1],
    [VM WAN],[10.41.107.10],
    [VM USUARIOS],[192.168.10.10],
    [VM ADMINISTRACION],[192.168.30.10],
    [VM SERVIDORESA],[192.168.20.10],
    [VM SERVIDORESB],[44.0.51.10],
  )
]

#pagebreak()

== 3.

#align(center)[
  #table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: center + horizon,
    fill: (x, y) => if y == 0 or x == 0 { luma(240) } else { none },
    stroke: 0.5pt + luma(150),
    
    [Desde \\ Hacia], [*WAN*], [*LAN*], [*Admin.*], [*Servidores A*], [*Servidores B*],
    
    [*WAN*], na, block, block, limited, limited,
    [*LAN*], permit, na, block, block_by_defect, block_by_defect,
    [*Admin.*], limited, block_by_defect, na, permit, permit,
    [*Servidores A*], permit, block, block, na, permit,
    [*Servidores B*], permit, block, block, permit, na,
  )
]
Bloqueado\*: Implica que esta bloqueado por defecto ya que no se especificó queda con la configuración inicial.

Los limitados de WAN a servidores A y B  implican que solo se puede acceder mediante TCP por el puerto 8000.

El limitado de Admin a WAN es porque solo permito ciertos servicios (http, https, DNS, icmp) que son los fundamentales para tareas de actualización o diagnóstico.

== 4.
A continuación voy a aclarar cada regla configurada en el firewall.

- WAN:
  - _*No poder acceder a la red de admin desde una red externa:*_ Es bastante autodeclarativo el nombre, pero impido que la interfaz WAN inicie una conexión con ADMINISTRACION, siendo WAN la única forma de acceder desde la red a admin.
  - _*No poder acceder a la LAN desde internet:*_ Similar a lo anterior, impide la conexión de redes exxternas a la interfaz LAN/USUARIOS.
  - _*NAT publicar servicio HTTP mediante WAN:*_ Regla que se genera por la configuración del port foward para permitir el tráfico entrante al puerto 8000 del servidor A.
  - _*Permitir HTTP hacia servidores B:*_ Permite solo el tráfico al puerto 8000 del servidor B. Se permite el acceso directo a la IP enrutable del servidor sin NAT, ya que es IP pública. 

- LAN: 
  - _*Block hacia admin:*_ Bloquear el acceso a la intefaz de ADMINISTRACION.
  - _*Salida con WAN:*_ Permite que los USUARIOS puedan acceder a la red externa/internet.

- ADMINISTRACION:
  - _*Permitir que admin acceda a la GUI de pfSense:*_ Permite el acceso al propio firewall.
  - _*Permitir acceso a servidores (A y B):*_ Habilita el acceso a los servidores desde la ADMINISTRACION.
  - _*Acceso a la red externa/internet (dns, http, https, icmp):*_ Solo permito ciertas conexiones a servicios externos para actualización de software o diagnóstico, asi no esta tan expuesto. Permito dns para poder resolver direcciones, http/https para acceder a la web e icmp para cosas como poder hacer `ping`.

- SERVIDORESA:
  - _*No acceder a (admin y LAN):*_ Bloquea el poder iniciar conexiones con ADMINISTRACION y LAN.
  - _*Iniciar conexiones hacia la red externa/internet:*_ Permite el paso a cualquier destino.

- SERVIDORESB:
  - _*No acceder a admin / Bloquear acceso a LAN:*_ Bloquea el poder iniciar conexiones con ADMINISTRACION y LAN.
  - _*Permitir acceso a red externa/internet:*_ Permite al servidor salir al exterior.

= Tengo que cambiar el acceso a servA y servB bloqueandolos entre si y que solo puedan acceder mediante la red.

== 5.

