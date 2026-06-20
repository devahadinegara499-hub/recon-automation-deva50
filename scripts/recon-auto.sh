#!/bin/bash

# ============================================================
# Nama Script  : recon-auto.sh
# Deskripsi    : Automated subdomain enumeration & live host probing
# Tools        : subfinder, httpx, anew
# Author       : [Nama Anda]
# Tanggal      : $(date +%Y-%m-%d)
# ============================================================

# --- Konfigurasi ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

INPUT_FILE="$PROJECT_ROOT/input/domains.txt"
OUTPUT_DIR="$PROJECT_ROOT/output"
ALL_SUBDOMAINS="$OUTPUT_DIR/all-subdomains.txt"
LIVE_HOSTS="$OUTPUT_DIR/live.txt"
LOG_DIR="$PROJECT_ROOT/logs"
PROGRESS_LOG="$LOG_DIR/progress.log"
ERROR_LOG="$LOG_DIR/errors.log"

# --- Fungsi Logging ---
log_progress() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$PROGRESS_LOG"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$ERROR_LOG" >&2
}

# --- Fungsi Cleanup ---
cleanup() {
    log_progress "Script dihentikan. Membersihkan proses..."
    exit 1
}
trap cleanup SIGINT SIGTERM

# --- Validasi Awal ---
log_progress "=== MEMULAI RECON AUTOMATION ==="

# Cek apakah file input ada
if [[ ! -f "$INPUT_FILE" ]]; then
    log_error "File input tidak ditemukan: $INPUT_FILE"
    exit 1
fi

# Cek apakah tools tersedia
for tool in subfinder httpx anew; do
    if ! command -v "$tool" &> /dev/null; then
        log_error "$tool tidak ditemukan. Pastikan sudah terinstall."
        exit 1
    fi
done

# --- Baca daftar domain dari file ---
mapfile -t domains < "$INPUT_FILE"

if [[ ${#domains[@]} -eq 0 ]]; then
    log_error "File input kosong. Tambahkan minimal 5 domain."
    exit 1
fi

log_progress "Ditemukan ${#domains[@]} domain yang akan diproses."

# --- Inisialisasi file output ---
> "$ALL_SUBDOMAINS"
> "$LIVE_HOSTS"

# --- Loop setiap domain ---
for domain in "${domains[@]}"; do
    # Skip baris kosong
    [[ -z "$domain" ]] && continue
    
    log_progress "Memproses domain: $domain"
    
    # --- Step 1: Subdomain Enumeration dengan subfinder ---
    log_progress "  → Menjalankan subfinder untuk $domain"
    
    # Jalankan subfinder, redirect stderr ke error log
    if ! subfinder -d "$domain" -silent 2>>"$ERROR_LOG" | anew "$ALL_SUBDOMAINS" >> "$ALL_SUBDOMAINS"; then
        log_error "subfinder gagal untuk $domain"
        continue
    fi
    
    # --- Step 2: Filter live hosts dengan httpx ---
    log_progress "  → Menjalankan httpx untuk memfilter live hosts dari $domain"
    
    # Ambil subdomain milik domain ini dari all-subdomains.txt
    # Kemudian pipe ke httpx untuk probing
    if ! grep "\.$domain$" "$ALL_SUBDOMAINS" 2>/dev/null | httpx -silent -status-code -title 2>>"$ERROR_LOG" | anew "$LIVE_HOSTS" >> "$LIVE_HOSTS"; then
        log_error "httpx gagal untuk $domain"
        continue
    fi
    
    log_progress "  → Selesai untuk $domain"
done

# --- Statistik ---
total_subdomains=$(wc -l < "$ALL_SUBDOMAINS" 2>/dev/null || echo 0)
total_live=$(wc -l < "$LIVE_HOSTS" 2>/dev/null || echo 0)

log_progress "=== RECON SELESAI ==="
log_progress "Total subdomain unik: $total_subdomains"
log_progress "Total live hosts: $total_live"
log_progress "Hasil disimpan di: $ALL_SUBDOMAINS dan $LIVE_HOSTS"

# Tampilkan 5 live host pertama sebagai contoh
if [[ $total_live -gt 0 ]]; then
    log_progress "Contoh live hosts (5 pertama):"
    head -n 5 "$LIVE_HOSTS" | while read -r line; do
        log_progress "  $line"
    done
fi

exit 0
