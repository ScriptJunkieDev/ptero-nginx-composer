#!/bin/ash

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

log_success() { echo -e "${GREEN}[SUCCESS] $1${RESET}"; }
log_warning() { echo -e "${YELLOW}[WARNING] $1${RESET}"; }
log_error()   { echo -e "${RED}[ERROR] $1${RESET}"; }
log_info()    { echo -e "[INFO] $1"; }

# Clean up temp directory
log_info "Cleaning up temporary files..."
rm -rf /home/container/tmp/* || { log_error "Failed to remove temporary files."; exit 1; }
log_success "Temporary files removed successfully."

# ----------------------------
# Composer install (Laravel deps)
# ----------------------------
cd /home/container/webroot || { log_error "webroot not found"; exit 1; }

if [ "${RUN_COMPOSER_INSTALL:-true}" = "true" ] || [ "${RUN_COMPOSER_INSTALL:-1}" = "1" ]; then
  if [ -f composer.json ]; then
    if [ ! -f vendor/autoload.php ]; then
      log_info "Running composer install..."
      composer install --no-interaction --prefer-dist ${COMPOSER_FLAGS:---no-dev --optimize-autoloader} \
        || { log_error "composer install failed"; exit 1; }
      log_success "Composer install completed."
    else
      log_success "vendor/autoload.php exists; skipping composer install."
    fi
  else
    log_warning "composer.json not found in /home/container/webroot; skipping composer."
  fi
else
  log_warning "RUN_COMPOSER_INSTALL disabled; skipping composer."
fi

# Ensure .env exists
if [ ! -f .env ] && [ -f .env.example ]; then
cp .env.example .env
fi

# Generate APP_KEY if missing
if [ -f artisan ] && [ -f .env ] && ! grep -q '^APP_KEY=base64:' .env; then
  php artisan key:generate --force || true
fi

if [ "${RUN_OPTIMIZE_CLEAR:-1}" = "1" ] || [ "${RUN_OPTIMIZE_CLEAR:-true}" = "true" ]; then
  if [ -f artisan ]; then
    log_info "Running php artisan optimize:clear..."
    php artisan optimize:clear || true
  fi
fi

log_info "Starting PHP-FPM..."
php-fpm --fpm-config /home/container/php-fpm/php-fpm.conf --daemonize \
  || { log_error "Failed to start PHP-FPM."; exit 1; }
log_success "PHP-FPM started successfully."

log_info "Starting NGINX..."
echo "[SUCCESS] Web server is running. All services started successfully."
exec /usr/sbin/nginx -c /home/container/nginx/nginx.conf -p /home/container/