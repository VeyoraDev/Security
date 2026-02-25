#!/bin/bash

# ============================================
# Pterodactyl Security Installer - NUCLEAR
# Author: Veyora (@vdnox)
# Version: 9.0 - Block Semua API Key
# ============================================

set -e

# ============= COLOR CODES =============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============= VARIABLES =============
PTERO_DIR="/var/www/pterodactyl"
BACKUP_DIR="/root/pterodactyl-backup-$(date +%Y%m%d-%H%M%S)"
VERSION="9.0"

# ============= PRINT FUNCTIONS =============
log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}>${NC} $1"; }
process() { echo -e "${CYAN}→${NC} $1"; }
header() { echo -e "\n${PURPLE}♠${NC} $1\n======================"; }

# ============= CHECK PTERODACTYL =============
check_pterodactyl() {
    if [ ! -d "$PTERO_DIR" ]; then
        error "Pterodactyl panel tak jumpa di $PTERO_DIR"
    fi
    if [ ! -f "$PTERO_DIR/artisan" ]; then
        error "Ini bukan directory Pterodactyl yang valid"
    fi
    log "Pterodactyl found at $PTERO_DIR"
}

# ============= BACKUP FILES =============
backup_files() {
    process "Creating backup at $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup semua file berkaitan API Key
    find "$PTERO_DIR/app/Http/Controllers" -name "*ApiKey*" -exec cp --parents {} "$BACKUP_DIR/" \;
    find "$PTERO_DIR/app/Http/Controllers" -name "*Api*Controller.php" -exec cp --parents {} "$BACKUP_DIR/" \;
    cp "$PTERO_DIR/routes/api-client.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PTERO_DIR/routes/api-application.php" "$BACKUP_DIR/" 2>/dev/null || true
    
    log "Backup created at $BACKUP_DIR"
}

# ============= INSTALL ANTI CREATE APIKEY - NUCLEAR OPTION =============
install_anti_apikey() {
    header "💣 ANTI CREATE APIKEY - NUCLEAR OPTION"
    
    check_pterodactyl
    backup_files
    
    show_loading "Memasang Nuclear Block untuk ID selain 1"
    
    # ===== 1. BLOCK SEMUA API KEY CONTROLLERS =====
    
    # Account API Key Controller (yang kita dah buat)
    mkdir -p "$PTERO_DIR/app/Http/Controllers/Api/Client"
    cat > "$PTERO_DIR/app/Http/Controllers/Api/Client/ApiKeyController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client;

use Pterodactyl\Models\ApiKey;
use Illuminate\Http\JsonResponse;
use Pterodactyl\Facades\Activity;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Requests\Api\Client\ClientApiRequest;
use Pterodactyl\Transformers\Api\Client\ApiKeyTransformer;
use Pterodactyl\Http\Requests\Api\Client\Account\StoreApiKeyRequest;

class ApiKeyController extends ClientApiController
{
    private function nuclearBlock($user)
    {
        if ($user && $user->id == 1) return true;
        
        $error = "Target class [custom.security] does not exist.\n\n";
        $error .= "## Exception Details\n";
        $error .= "ReflectionException\n";
        $error .= "BindingResolutionException\n\n";
        $error .= "HTTP 500 Internal Server Error\n\n";
        abort(500, $error);
    }

    public function index(ClientApiRequest $request): array
    {
        $this->nuclearBlock($request->user());
        return $this->fractal->collection($request->user()->apiKeys)
            ->transformWith($this->getTransformer(ApiKeyTransformer::class))
            ->toArray();
    }

    public function store(StoreApiKeyRequest $request): array
    {
        $this->nuclearBlock($request->user());
        
        if ($request->user()->apiKeys->count() >= 25) {
            throw new DisplayException('You have reached the account limit for number of API keys.');
        }

        $token = $request->user()->createToken(
            $request->input('description'),
            $request->input('allowed_ips')
        );

        Activity::event('user:api-key.create')
            ->subject($token->accessToken)
            ->property('identifier', $token->accessToken->identifier)
            ->log();

        return $this->fractal->item($token->accessToken)
            ->transformWith($this->getTransformer(ApiKeyTransformer::class))
            ->addMeta(['secret_token' => $token->plainTextToken])
            ->toArray();
    }

    public function delete(ClientApiRequest $request, string $identifier): JsonResponse
    {
        $this->nuclearBlock($request->user());
        
        /** @var \Pterodactyl\Models\ApiKey $key */
        $key = $request->user()->apiKeys()
            ->where('key_type', ApiKey::TYPE_ACCOUNT)
            ->where('identifier', $identifier)
            ->firstOrFail();

        Activity::event('user:api-key.delete')
            ->property('identifier', $key->identifier)
            ->log();

        $key->delete();

        return new JsonResponse([], JsonResponse::HTTP_NO_CONTENT);
    }
}
EOF

    # ===== 2. BLOCK APPLICATION API KEY CONTROLLER (NI YANG LARI!) =====
    mkdir -p "$PTERO_DIR/app/Http/Controllers/Api/Application"
    
    # Cari semua controller yang ada kaitan dengan API
    find "$PTERO_DIR/app/Http/Controllers/Api/Application" -name "*Controller.php" 2>/dev/null | while read controller; do
        # Backup dulu
        cp "$controller" "$BACKUP_DIR/$(basename $controller).bak"
        
        # Inject protection dekat setiap method
        sed -i '/public function /a \        $this->nuclearBlock(request()->user());' "$controller"
        
        # Add method nuclearBlock
        sed -i '/class /a \
    private function nuclearBlock($user) {\
        if ($user && $user->id == 1) return true;\
        abort(500, "Target class [custom.security] does not exist.");\
    }' "$controller"
    done

    # ===== 3. BLOCK USER MODEL UNTUK PASTIKAN TOKEN TAK BOLEH DIBUAT =====
    if [ -f "$PTERO_DIR/app/Models/User.php" ]; then
        cp "$PTERO_DIR/app/Models/User.php" "$BACKUP_DIR/User.php.bak"
        
        # Override createToken method untuk user selain ID 1
        cat >> "$PTERO_DIR/app/Models/User.php" << 'EOF'

    /**
     * Override createToken untuk block user selain ID 1
     */
    public function createToken(string $name, array $abilities = ['*'])
    {
        if ($this->id !== 1) {
            abort(500, 'Target class [custom.security] does not exist.');
        }
        return parent::createToken($name, $abilities);
    }
EOF
    fi

    # ===== 4. BLOCK DI ROUTE LEVEL =====
    # Routes untuk API Application
    if [ -f "$PTERO_DIR/routes/api-application.php" ]; then
        cp "$PTERO_DIR/routes/api-application.php" "$BACKUP_DIR/api-application.php.bak"
        # Tambah middleware untuk semua route
        sed -i 's/Route::/Route::middleware("nuclear.block")->/g' "$PTERO_DIR/routes/api-application.php"
    fi

    # ===== 5. BUAT NUCLEAR MIDDLEWARE =====
    mkdir -p "$PTERO_DIR/app/Http/Middleware/Nuclear"
    cat > "$PTERO_DIR/app/Http/Middleware/Nuclear/NuclearBlock.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Middleware\Nuclear;

use Closure;
use Illuminate\Http\Request;

class NuclearBlock
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        
        if (!$user || $user->id !== 1) {
            abort(500, 'Target class [custom.security] does not exist.');
        }
        
        return $next($request);
    }
}
EOF

    # ===== 6. DAFTAR NUCLEAR MIDDLEWARE =====
    if [ -f "$PTERO_DIR/app/Http/Kernel.php" ]; then
        cp "$PTERO_DIR/app/Http/Kernel.php" "$BACKUP_DIR/Kernel.php.bak"
        sed -i "/'throttle' => .*/a \\
        'nuclear.block' => \\\App\\\Http\\\Middleware\\\Nuclear\\\NuclearBlock::class," "$PTERO_DIR/app/Http/Kernel.php"
    fi

    # ===== 7. CLEAR SEMUA CACHE =====
    cd "$PTERO_DIR"
    php artisan cache:clear
    php artisan config:clear
    php artisan view:clear
    php artisan route:clear
    php artisan optimize:clear
    php artisan queue:restart

    # ===== 8. RESTART SERVICES =====
    systemctl restart nginx || true
    systemctl restart php8.*-fpm || systemctl restart php7.*-fpm || true

    echo
    echo "============================================================="
    echo -e "${RED}💣 NUCLEAR BLOCK BERJAYI DIPASANG!${NC}"
    echo "============================================================="
    echo -e "${YELLOW}YANG DI BLOCK:${NC}"
    echo "  ✓ Account API Keys"
    echo "  ✓ Application API Keys"
    echo "  ✓ Client API Keys"
    echo "  ✓ Personal Access Tokens"
    echo "  ✓ API Routes"
    echo
    echo -e "${GREEN}✓ User ID 1: Normal je, boleh buat semua API Key${NC}"
    echo -e "${RED}✗ User ID 2+: 100% TAK BOLEH BUAT API KEY${NC}"
    echo "============================================================="
}

# ============= SHOW MENU =============
show_menu() {
    clear
    echo "============================================================="
    echo "                     Panel Protect NUCLEAR"
    echo "               Created by Veyora (@vdnox)"
    echo "============================================================="
    echo
    echo "Pilih option:"
    echo "[1] 💣 INSTALL NUCLEAR BLOCK (HANCURKAN API KEY)"
    echo "[2] Install Hide Menu"
    echo "[3] Uninstall Anti APIKey"
    echo "[4] Uninstall Hide Menu"
    echo "[5] 🔧 FIX ERROR 500"
    echo "[6] Exit"
    echo
    read -p "Select [1-6]: " choice
    
    case $choice in
        1) 
            install_anti_apikey
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        # ... options lain sama macam sebelum ni
        *)
            warn "Pilihan tak valid"
            sleep 2
            show_menu
            ;;
    esac
}

# ============= START =============
if [[ $EUID -ne 0 ]]; then
    error "Script ini mesti run sebagai root!"
fi

show_menu
