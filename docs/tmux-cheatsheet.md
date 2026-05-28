# Tmux cheatsheet

Atajos según `~/.config/tmux/tmux.conf` en este repo.

## Omarchy / Hyprland

| Atajo | Acción |
| --- | --- |
| `Super + Alt + Return` | Abrir o adjuntarse a la sesión tmux `Work` |
| `Super + Return` | Abrir terminal en el cwd actual, incluyendo el pane activo de tmux |

## Prefijo

| Atajo | Acción |
| --- | --- |
| `Ctrl + Space` | Prefijo principal |
| `Ctrl + b` | Prefijo alternativo |
| `Prefix + q` | Recargar config de tmux |

## Panes

| Atajo | Acción |
| --- | --- |
| `Prefix + h` | Split vertical, crea pane abajo |
| `Prefix + v` | Split horizontal, crea pane a la derecha |
| `Prefix + x` | Cerrar pane |
| `Ctrl + Alt + ←` | Mover foco al pane izquierdo |
| `Ctrl + Alt + →` | Mover foco al pane derecho |
| `Ctrl + Alt + ↑` | Mover foco al pane superior |
| `Ctrl + Alt + ↓` | Mover foco al pane inferior |
| `Ctrl + Alt + Shift + ←` | Reducir pane hacia la izquierda |
| `Ctrl + Alt + Shift + →` | Aumentar pane hacia la derecha |
| `Ctrl + Alt + Shift + ↑` | Reducir pane hacia arriba |
| `Ctrl + Alt + Shift + ↓` | Aumentar pane hacia abajo |

## Windows

| Atajo | Acción |
| --- | --- |
| `Prefix + c` | Crear window en el directorio actual |
| `Prefix + k` | Cerrar window |
| `Prefix + r` | Renombrar window |
| `Alt + 1` .. `Alt + 9` | Ir a window 1..9 |
| `Alt + ←` | Window anterior |
| `Alt + →` | Window siguiente |
| `Alt + Shift + ←` | Mover window a la izquierda |
| `Alt + Shift + →` | Mover window a la derecha |

## Sessions

| Atajo | Acción |
| --- | --- |
| `Prefix + C` | Crear nueva sesión |
| `Prefix + K` | Cerrar sesión |
| `Prefix + R` | Renombrar sesión |
| `Prefix + P` | Sesión anterior |
| `Prefix + N` | Sesión siguiente |
| `Alt + ↑` | Sesión anterior |
| `Alt + ↓` | Sesión siguiente |

## Copy mode

| Atajo | Acción |
| --- | --- |
| `Prefix + [` | Entrar a copy mode |
| `v` | Iniciar selección visual |
| `y` | Copiar selección y salir |
| `/` | Buscar hacia adelante |
| `?` | Buscar hacia atrás |
| `n` | Siguiente resultado |
| `N` | Resultado anterior |

## Comandos útiles

```bash
# Crear o adjuntarse a la sesión Work
tmux new-session -A -s Work

# Listar sesiones
tmux ls

# Adjuntarse a una sesión
tmux attach -t Work

# Matar una sesión
tmux kill-session -t Work

# Recargar config manualmente dentro de tmux
tmux source-file ~/.config/tmux/tmux.conf
```
