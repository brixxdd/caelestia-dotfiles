#!/bin/bash
# =============================================
# Gestor de Dispositivos: USB, HDD y Android
# Requiere: zenity, gvfs-mtp, jmtpfs o simple-mtpfs, ntfs-3g, thunar
# =============================================

BASE="/mnt"
ANDROID_MOUNT="$BASE/android"

# ── Colores para notificaciones zenity ────────────────────────────────────────
function montar_usb() {
  mapfile -t DISKS < <(lsblk -rpo NAME,FSTYPE,LABEL,SIZE,TYPE \
    | awk '$5=="part" && $2!="" {print}')

  if [ ${#DISKS[@]} -eq 0 ]; then
    zenity --warning --text="No se encontraron particiones disponibles." --timeout=3
    return
  fi

  LIST=()
  for i in "${!DISKS[@]}"; do
    NAME=$(awk '{print $1}' <<< "${DISKS[$i]}")
    FSTYPE=$(awk '{print $2}' <<< "${DISKS[$i]}")
    LABEL=$(awk '{print $3}' <<< "${DISKS[$i]}")
    SIZE=$(awk '{print $4}' <<< "${DISKS[$i]}")
    [ "$LABEL" = "-" ] && LABEL=""
    LIST+=("$NAME" "$FSTYPE" "${LABEL:-sin etiqueta}" "$SIZE")
  done

  SELECTED=$(zenity --list \
    --title="Montar USB / HDD" \
    --text="Selecciona la partición a montar:" \
    --column="Dispositivo" --column="Sistema de archivos" \
    --column="Etiqueta" --column="Tamaño" \
    "${LIST[@]}" \
    --height=320 --width=520)

  [ -z "$SELECTED" ] && return

  # Obtener info del dispositivo seleccionado
  DISK_INFO=$(lsblk -rpo NAME,FSTYPE,LABEL,SIZE,TYPE \
    | awk -v dev="$SELECTED" '$1==dev {print}')
  FSTYPE=$(awk '{print $2}' <<< "$DISK_INFO")
  LABEL=$(awk '{print $3}' <<< "$DISK_INFO")
  [ -z "$LABEL" ] || [ "$LABEL" = "-" ] && LABEL="USB"

  MOUNTPOINT="$BASE/$LABEL"
  sudo mkdir -p "$MOUNTPOINT"

  # Montaje según el sistema de archivos
  case "$FSTYPE" in
    ntfs|ntfs-3g)
      sudo mount -t ntfs-3g -o uid=$(id -u),gid=$(id -g),fmask=0022,dmask=0022 \
        "$SELECTED" "$MOUNTPOINT"
      ;;
    exfat)
      sudo mount -t exfat -o uid=$(id -u),gid=$(id -g) \
        "$SELECTED" "$MOUNTPOINT"
      ;;
    vfat|fat32)
      sudo mount -t vfat -o uid=$(id -u),gid=$(id -g),fmask=0022,dmask=0022 \
        "$SELECTED" "$MOUNTPOINT"
      ;;
    *)
      sudo mount "$SELECTED" "$MOUNTPOINT"
      ;;
  esac

  if [ $? -eq 0 ]; then
    zenity --info \
      --text="✅ Montado exitosamente\n\n<b>$SELECTED</b> → $MOUNTPOINT\nSistema de archivos: $FSTYPE" \
      --timeout=3
    thunar "$MOUNTPOINT" &
  else
    zenity --error \
      --text="❌ Error al montar $SELECTED\n\nVerifica si necesitas instalar:\n• ntfs-3g para NTFS\n• exfatutils para exFAT"
    sudo rmdir "$MOUNTPOINT" 2>/dev/null
  fi
}

# ── Android por MTP ───────────────────────────────────────────────────────────
function montar_android() {
  # Detectar dispositivos Android conectados
  if ! command -v jmtpfs &>/dev/null && ! command -v simple-mtpfs &>/dev/null; then
    zenity --error \
      --text="❌ No se encontró herramienta MTP.\n\nInstala una de estas:\n• sudo pacman -S jmtpfs\n• sudo pacman -S simple-mtpfs\n• sudo pacman -S gvfs-mtp (para Thunar automático)"
    return
  fi

  # Listar dispositivos MTP disponibles
  if command -v jmtpfs &>/dev/null; then
    DEVICES=$(jmtpfs -l 2>&1 | grep -v "^$\|^Available\|^No\|libmtp")
  else
    DEVICES=$(simple-mtpfs --list-devices 2>&1 | grep -v "^$\|^Available")
  fi

  if [ -z "$DEVICES" ]; then
    zenity --warning \
      --text="⚠️ No se detectó ningún Android.\n\nAsegúrate de:\n1. Tener el cable USB conectado\n2. Desbloquear el teléfono\n3. Seleccionar <b>Transferencia de archivos (MTP)</b>\n   en la notificación USB del teléfono\n4. Haber dado permisos de desarrollador si es necesario" \
      --width=400
    return
  fi

  sudo mkdir -p "$ANDROID_MOUNT"

  if command -v jmtpfs &>/dev/null; then
    jmtpfs "$ANDROID_MOUNT" 2>/dev/null
    RESULT=$?
  else
    simple-mtpfs --device 1 "$ANDROID_MOUNT" 2>/dev/null
    RESULT=$?
  fi

  if [ $RESULT -eq 0 ]; then
    zenity --info \
      --text="✅ Android montado en\n$ANDROID_MOUNT" \
      --timeout=3
    thunar "$ANDROID_MOUNT" &
  else
    zenity --error \
      --text="❌ No se pudo montar el Android.\n\nConsejos:\n• Desbloquea el teléfono antes de conectar\n• Cambia a modo MTP en el menú USB\n• Prueba otro cable USB\n• Instala: sudo pacman -S android-udev"
    sudo rmdir "$ANDROID_MOUNT" 2>/dev/null
  fi
}

# ── Desmontar ─────────────────────────────────────────────────────────────────
function desmontar() {
  # USB/HDD normales
  mapfile -t MOUNTS_BLOCK < <(mount | grep "$BASE" | grep -v "android\|mtp\|fuse" | awk '{print $3}')
  # Android / MTP
  mapfile -t MOUNTS_MTP < <(mount | grep -E "mtp|fuse.*android|$ANDROID_MOUNT" | awk '{print $3}')

  ALL_MOUNTS=("${MOUNTS_BLOCK[@]}" "${MOUNTS_MTP[@]}")

  if [ ${#ALL_MOUNTS[@]} -eq 0 ]; then
    zenity --warning --text="No hay dispositivos montados en $BASE" --timeout=2
    return
  fi

  LIST=()
  for i in "${!ALL_MOUNTS[@]}"; do
    TYPE="USB/HDD"
    # Detectar si es MTP
    if mount | grep "${ALL_MOUNTS[$i]}" | grep -qE "mtp|fuse"; then
      TYPE="Android"
    fi
    LIST+=("$((i+1))" "${ALL_MOUNTS[$i]}" "$TYPE")
  done

  CHOICE=$(zenity --list \
    --title="Desmontar dispositivo" \
    --column="N°" --column="Punto de montaje" --column="Tipo" \
    "${LIST[@]}" \
    --height=300 --width=420)

  [ -z "$CHOICE" ] && return
  INDEX=$((CHOICE-1))
  TARGET="${ALL_MOUNTS[$INDEX]}"

  # Desmontar según tipo
  if mount | grep "$TARGET" | grep -qE "mtp|fuse"; then
    fusermount -u "$TARGET" 2>/dev/null || umount "$TARGET" 2>/dev/null
  else
    sudo umount "$TARGET"
  fi

  if [ $? -eq 0 ]; then
    zenity --info --text="✅ Desmontado correctamente:\n$TARGET" --timeout=2
    sudo rmdir "$TARGET" 2>/dev/null
  else
    zenity --error --text="❌ No se pudo desmontar $TARGET\n\nAsegúrate de cerrar todos los archivos abiertos."
  fi
}

# ── Ver montados ──────────────────────────────────────────────────────────────
function listar_montados() {
  LISTA=$(mount | grep "$BASE" | awk '{printf "%-30s %-15s %s\n", $3, $5, $6}')
  if [ -z "$LISTA" ]; then
    zenity --info --title="Dispositivos montados" \
      --text="No hay ningún dispositivo montado en $BASE" --timeout=2
  else
    zenity --info --title="Dispositivos montados" \
      --text="<b>Punto de montaje          Tipo            Opciones</b>\n\n$LISTA" \
      --width=600
  fi
}

# ── Verificar dependencias al inicio ─────────────────────────────────────────
function check_deps() {
  local missing=()
  command -v zenity    &>/dev/null || missing+=("zenity")
  command -v lsblk     &>/dev/null || missing+=("util-linux")
  command -v thunar    &>/dev/null || missing+=("thunar")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Dependencias faltantes: ${missing[*]}"
    echo "Instala con: sudo pacman -S ${missing[*]}"
    exit 1
  fi
}

# ── Menú principal ────────────────────────────────────────────────────────────
check_deps

while true; do
  OPCION=$(zenity --list \
    --title="Gestor de Dispositivos" \
    --text="Selecciona una acción:" \
    --column="Opción" --column="Acción" \
    "1" "💾  Montar USB / HDD" \
    "2" "📱  Montar Android (MTP)" \
    "3" "⏏   Desmontar dispositivo" \
    "4" "📋  Ver montados" \
    "5" "❌  Salir" \
    --height=320 --width=380)

  [ $? -ne 0 ] && break

  case $OPCION in
    1) montar_usb ;;
    2) montar_android ;;
    3) desmontar ;;
    4) listar_montados ;;
    5) break ;;
  esac
done
