#!/usr/bin/env bash
# Uso: test-adguard.sh [interfaz] [IP-de-AdGuard]
# Solo consulta DNS; no modifica la conexión ni renueva DHCP.
# Salidas: 0 = correcto, 1 = comprobaciones fallidas, 2 = error de diagnóstico.
set -u
export LC_ALL=C

iface="${1:-wlp195s0}"
adguard="${2:-192.168.0.122}"
failures=0

for cmd in nmcli dig grep; do
  command -v "$cmd" >/dev/null || {
    printf "ERROR: falta %s\n" "$cmd" >&2
    exit 2
  }
done

ok() { printf "OK: %s\n" "$1"; }
fail() { printf "FALLO: %s\n" "$1"; failures=$((failures + 1)); }

printf "Interfaz: %s | AdGuard esperado: %s\n\n" "$iface" "$adguard"
if ! dns=$(nmcli --escape no -t -f IP4.DNS,IP6.DNS device show "$iface"); then
  printf "ERROR: no se pudo consultar la interfaz.\n" >&2
  exit 2
fi

found=0
while IFS=: read -r field server; do
  [[ "$field" == IP4.DNS* || "$field" == IP6.DNS* ]] || continue
  [[ -z "$server" ]] && continue
  found=1
  if [[ "$server" == "$adguard" ]]; then
    ok "DNS recibido: $server"
  else
    fail "DNS adicional recibido: $server"
  fi
done <<< "$dns"
(( found )) || fail "La interfaz no tiene servidores DNS."

check_block() {
  local label="$1" type="$2" expected="$3" answer
  shift 3
  if ! answer=$(dig +time=3 +tries=1 +short "$@" doubleclick.net "$type" 2>&1); then
    fail "$label: consulta fallida: $answer"
  elif [[ "$answer" == "$expected" ]]; then
    ok "$label: $answer"
  else
    fail "$label: respuesta ${answer:-vacía}; se esperaba $expected"
  fi
}

check_block "AdGuard directo A" A 0.0.0.0 "@$adguard"
check_block "DNS del sistema A" A 0.0.0.0
check_block "AdGuard directo AAAA" AAAA :: "@$adguard"
check_block "DNS del sistema AAAA" AAAA ::

if ! answer=$(dig +time=3 +tries=1 +short example.com A 2>&1); then
  fail "Resolución normal: $answer"
elif printf "%s\n" "$answer" | grep -Eq "^[1-9][0-9]{0,2}(\.[0-9]{1,3}){3}$"; then
  ok "example.com resuelve normalmente."
else
  fail "example.com no devuelve una dirección IPv4 válida: ${answer:-vacía}"
fi

if (( failures )); then
  printf "\nResultado: %d comprobaciones fallaron.\n" "$failures"
  printf "Si acabas de guardar el router, reconecta el Wi-Fi y repite.\n"
  exit 1
fi

printf "\nResultado: DNS y filtrado correctos en esta conexión.\n"
