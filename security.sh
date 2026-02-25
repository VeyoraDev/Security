#!/bin/bash

# ============================================
# Pterodactyl Security Installer - PTLA PROTECT
# Author: Veyora (@vdnox)
# Version: 12.0 - Application API Protection
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
VERSION="12.0"

# ============= PRINT FUNCTIONS =============
log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}>${NC} $1"; }
process() { echo -e "${CYAN}→${NC} $1"; }
header() { echo -e "\n${PURPLE}♠${NC} $1\n======================"; }

# ============= LOADING ANIMATION =============
show_loading() {
    local text=$1
    local duration=2
    local steps=20
    local step_duration=$(echo "scale=3; $duration/$steps" | bc)
    
    printf "    ${text} ["
    for ((i=0; i<steps; i++)); do
        printf "▰"
        sleep $step_duration
    done
    printf "] Done!\n"
}

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
    
    # Backup PTLA files
    [ -f "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php" ] && \
        cp "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php" "$BACKUP_DIR/"
    
    [ -f "$PTERO_DIR/routes/api-application.php" ] && \
        cp "$PTERO_DIR/routes/api-application.php" "$BACKUP_DIR/"
    
    [ -f "$PTERO_DIR/app/Http/Kernel.php" ] && \
        cp "$PTERO_DIR/app/Http/Kernel.php" "$BACKUP_DIR/"
    
    # Backup PTLC files (just in case)
    [ -f "$PTERO_DIR/app/Http/Controllers/Api/Client/ApiKeyController.php" ] && \
        cp "$PTERO_DIR/app/Http/Controllers/Api/Client/ApiKeyController.php" "$BACKUP_DIR/"
    
    log "Backup created at $BACKUP_DIR"
}

# ============= CLEAR CACHE =============
clear_cache() {
    process "Clearing application cache..."
    cd "$PTERO_DIR"
    php artisan cache:clear
    php artisan config:clear
    php artisan view:clear
    php artisan route:clear
    log "Cache cleared"
}

# ============= INSTALL PROTECT APPLICATION API (PTLA) =============
install_protect_ptla() {
    header "🔒 PROTECT APPLICATION API (PTLA)"
    
    check_pterodactyl
    backup_files
    
    show_loading "Memasang Protection untuk Application API"
    
    # ===== 1. CREATE MIDDLEWARE =====
    process "Creating PTLA Protection Middleware..."
    
    mkdir -p "$PTERO_DIR/app/Http/Middleware/PTLA"
    
    cat > "$PTERO_DIR/app/Http/Middleware/PTLA/ProtectPTLA.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Middleware\PTLA;

use Closure;
use Illuminate\Http\Request;

class ProtectPTLA
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        
        // Log attempt for debugging
        error_log("PTLA Access Attempt - User ID: " . ($user->id ?? 'guest') . " - Path: " . $request->path());
        
        // Kalau user ID 1, bagi lalu
        if ($user && $user->id == 1) {
            return $next($request);
        }
        
        // Kalau bukan ID 1, bagi error "Target Class" macam gambar
        $error = "Target class [custom.security] does not exist.\n\n";
        $error .= "## Exception Details\n";
        $error .= "ReflectionException\n";
        $error .= "BindingResolutionException\n\n";
        $error .= "HTTP 500 Internal Server Error\n\n";
        $error .= "---\n\n";
        $error .= "## Stack Trace\n\n";
        $error .= "Illuminate\Contracts\Container\BindingResolutionException\n";
        $error .= "in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Container/Container.php (line 914)\n";
        $error .= "in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Container/Container.php -> build (line 795)\n";
        $error .= "in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Foundation/Application.php -> resolve (line 963)\n";
        $error .= "in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Container/Container.php -> resolve (line 731)\n";
        $error .= "in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Foundation/Application.php -> make (line 948)\n";
        $error .= "in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php -> make (line 172)\n";
        $error .= "Pipeline->Illuminate\Pipelines\Closure()\n";
        $error .= "in /var/www/pterodactyl/app/Http/Middleware/AdminAuth/middleware.php (line 211)\n";
        
        abort(500, $error);
    }
}
EOF
    
    log "Middleware created"
    
    # ===== 2. REGISTER MIDDLEWARE IN KERNEL =====
    process "Registering middleware in Kernel.php..."
    
    if ! grep -q "ptla.protect" "$PTERO_DIR/app/Http/Kernel.php"; then
        sed -i "/'throttle' => .*/a \\
        'ptla.protect' => \\\App\\\Http\\\Middleware\\\PTLA\\\ProtectPTLA::class," "$PTERO_DIR/app/Http/Kernel.php"
        log "Middleware registered in Kernel.php"
    else
        warn "Middleware already registered"
    fi
    
    # ===== 3. PROTECT ROUTES =====
    process "Protecting Application API routes..."
    
    if [ -f "$PTERO_DIR/routes/api-application.php" ]; then
        # Backup dulu
        cp "$PTERO_DIR/routes/api-application.php" "$BACKUP_DIR/api-application.php"
        
        # Check if already protected
        if grep -q "ptla.protect" "$PTERO_DIR/routes/api-application.php"; then
            warn "Routes already protected"
        else
            # Add middleware to the application api group
            sed -i "s/'middleware' => \['api.application'\]/'middleware' => ['api.application', 'ptla.protect']/g" "$PTERO_DIR/routes/api-application.php"
            log "Application API routes protected"
        fi
    else
        warn "api-application.php not found"
    fi
    
    # ===== 4. SET PERMISSIONS =====
    process "Setting permissions..."
    chown -R www-data:www-data "$PTERO_DIR/app/Http/Middleware/PTLA"
    chmod -R 755 "$PTERO_DIR/app/Http/Middleware/PTLA"
    
    # ===== 5. CLEAR CACHE =====
    clear_cache
    
    echo
    echo "============================================================="
    echo -e "${GREEN}✅ PROTECT APPLICATION API BERJAYI DIPASANG!${NC}"
    echo "============================================================="
    echo -e "${YELLOW}HASILNYA:${NC}"
    echo -e "${GREEN}✓ User ID 1: Buka /admin/api → NORMAL${NC}"
    echo -e "${RED}✗ User ID 2+: Buka /admin/api → ERROR 'Target Class'${NC}"
    echo
    echo -e "${BLUE}Nota: PTLC (Client API) tetap NORMAL untuk semua user${NC}"
    echo "============================================================="
}

# ============= UNINSTALL PROTECT APPLICATION API =============
uninstall_protect_ptla() {
    header "🔓 UNINSTALL PROTECT APPLICATION API"
    
    check_pterodactyl
    
    warn "Ini akan unprotect Application API (PTLA) dan pulangkan ke normal"
    read -p "Teruskan? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Dibatalkan"
        return
    fi
    
    # ===== 1. RESTORE ROUTES =====
    process "Restoring Application API routes..."
    
    if [ -f "$BACKUP_DIR/api-application.php" ]; then
        cp "$BACKUP_DIR/api-application.php" "$PTERO_DIR/routes/api-application.php"
        log "Routes restored from backup"
    else
        # Remove middleware from routes
        sed -i "s/, 'ptla.protect'//g" "$PTERO_DIR/routes/api-application.php"
        sed -i "s/'ptla.protect', //g" "$PTERO_DIR/routes/api-application.php"
        log "Routes cleaned manually"
    fi
    
    # ===== 2. REMOVE MIDDLEWARE FROM KERNEL =====
    process "Removing middleware from Kernel.php..."
    
    if [ -f "$BACKUP_DIR/Kernel.php" ]; then
        cp "$BACKUP_DIR/Kernel.php" "$PTERO_DIR/app/Http/Kernel.php"
        log "Kernel.php restored from backup"
    else
        sed -i "/'ptla.protect'/d" "$PTERO_DIR/app/Http/Kernel.php"
        log "Middleware removed from Kernel.php"
    fi
    
    # ===== 3. REMOVE MIDDLEWARE FILES =====
    process "Removing middleware files..."
    
    if [ -d "$PTERO_DIR/app/Http/Middleware/PTLA" ]; then
        rm -rf "$PTERO_DIR/app/Http/Middleware/PTLA"
        log "Middleware directory removed"
    fi
    
    # ===== 4. CLEAR CACHE =====
    clear_cache
    
    echo
    echo "============================================================="
    echo -e "${GREEN}✅ PROTECT APPLICATION API TELAH DIUNINSTALL!${NC}"
    echo "============================================================="
    echo -e "${YELLOW}SEKARANG:${NC}"
    echo -e "${GREEN}✓ Semua user boleh akses /admin/api${NC}"
    echo "============================================================="
}

# ============= INSTALL HIDE MENU =============
install_hide_menu() {
    header "HIDE MENU - Pemasangan"
    
    check_pterodactyl
    backup_files
    
    show_loading "Memasang Hide Menu"
    
    # Create directory if not exists
    mkdir -p "$PTERO_DIR/resources/views/layouts"
    
    # Write the Blade template code dengan @if conditions
    cat > "$PTERO_DIR/resources/views/layouts/admin.blade.php" << 'EOF'
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>{{ config('app.name', 'Pterodactyl') }} - @yield('title')</title>
        <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
        <meta name="_token" content="{{ csrf_token() }}">

        <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
        <link rel="icon" type="image/png" href="/favicons/favicon-32x32.png" sizes="32x32">
        <link rel="icon" type="image/png" href="/favicons/favicon-16x16.png" sizes="16x16">
        <link rel="manifest" href="/favicons/manifest.json">
        <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#bc6e3c">
        <link rel="shortcut icon" href="/favicons/favicon.ico">
        <meta name="msapplication-config" content="/favicons/browserconfig.xml">
        <meta name="theme-color" content="#0e4688">

        @include('layouts.scripts')

        @section('scripts')
            {!! Theme::css('vendor/select2/select2.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/bootstrap/bootstrap.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/adminlte/admin.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/adminlte/colors/skin-blue.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/sweetalert/sweetalert.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/animate/animate.min.css?t={cache-version}') !!}
            {!! Theme::css('css/pterodactyl.css?t={cache-version}') !!}
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/ionicons/2.0.1/css/ionicons.min.css">

            <!--[if lt IE 9]>
            <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
            <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
            <![endif]-->
        @show
    </head>
    <body class="hold-transition skin-blue fixed sidebar-mini">
        <div class="wrapper">
            <header class="main-header">
                <a href="{{ route('index') }}" class="logo">
                    <span>{{ config('app.name', 'Pterodactyl') }}</span>
                </a>
                <nav class="navbar navbar-static-top">
                    <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
                        <span class="sr-only">Toggle navigation</span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <div class="navbar-custom-menu">
                        <ul class="nav navbar-nav">
                            <li class="user-menu">
                                <a href="{{ route('account') }}">
                                    <img src="https://www.gravatar.com/avatar/{{ md5(strtolower(Auth::user()->email)) }}?s=160" class="user-image" alt="User Image">
                                    <span class="hidden-xs">{{ Auth::user()->name_first }} {{ Auth::user()->name_last }}</span>
                                </a>
                            </li>
                            <li>
                                <li><a href="{{ route('index') }}" data-toggle="tooltip" data-placement="bottom" title="Exit Admin Control"><i class="fa fa-server"></i></a></li>
                            </li>
                            <li>
                                <li><a href="{{ route('auth.logout') }}" id="logoutButton" data-toggle="tooltip" data-placement="bottom" title="Logout"><i class="fa fa-sign-out"></i></a></li>
                            </li>
                        </ul>
                    </div>
                </nav>
            </header>
            <aside class="main-sidebar">
                <section class="sidebar">
                    <ul class="sidebar-menu">
                        <li class="header">BASIC ADMINISTRATION</li>
                        <li class="{{ Route::currentRouteName() !== 'admin.index' ?: 'active' }}">
                            <a href="{{ route('admin.index') }}">
                                <i class="fa fa-home"></i> <span>Overview</span>
                            </a>
                        </li>
{{-- ✅ Hanya tampil untuk user ID 1 --}}
@if(Auth::user()->id == 1)
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.settings') ?: 'active' }}">
    <a href="{{ route('admin.settings') }}">
        <i class="fa fa-wrench"></i> <span>Settings</span>
    </a>
</li>
@endif
{{-- ✅ Hanya tampil untuk user ID 1 --}}
@if(Auth::user()->id == 1)
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.api') ?: 'active' }}">
    <a href="{{ route('admin.api.index')}}">
        <i class="fa fa-gamepad"></i> <span>Application API</span>
    </a>
</li>
@endif
<li class="header">MANAGEMENT</li>

{{-- ✅ Hanya tampil untuk user ID 1 --}}
@if(Auth::user()->id == 1)
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.databases') ?: 'active' }}">
    <a href="{{ route('admin.databases') }}">
        <i class="fa fa-database"></i> <span>Databases</span>
    </a>
</li>
@endif

{{-- ✅ Hanya tampil untuk user ID 1 --}}
@if(Auth::user()->id == 1)
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.locations') ?: 'active' }}">
    <a href="{{ route('admin.locations') }}">
        <i class="fa fa-globe"></i> <span>Locations</span>
    </a>
</li>
@endif

{{-- ✅ Hanya tampil untuk user dengan ID 1 --}}
@if(Auth::user()->id == 1)
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.nodes') ?: 'active' }}">
    <a href="{{ route('admin.nodes') }}">
        <i class="fa fa-sitemap"></i> <span>Nodes</span>
    </a>
</li>
@endif

                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.servers') ?: 'active' }}">
                            <a href="{{ route('admin.servers') }}">
                                <i class="fa fa-server"></i> <span>Servers</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.users') ?: 'active' }}">
                            <a href="{{ route('admin.users') }}">
                                <i class="fa fa-users"></i> <span>Users</span>
                            </a>
                        </li>
{{-- ✅ Hanya tampil untuk admin utama --}}
@if(Auth::user()->id == 1)
    <li class="header">SERVICE MANAGEMENT</li>

    <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.mounts') ?: 'active' }}">
        <a href="{{ route('admin.mounts') }}">
            <i class="fa fa-magic"></i> <span>Mounts</span>
        </a>
    </li>

    <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.nests') ?: 'active' }}">
        <a href="{{ route('admin.nests') }}">
            <i class="fa fa-th-large"></i> <span>Nests</span>
        </a>
    </li>
@endif
                    </ul>
                </section>
            </aside>
            <div class="content-wrapper">
                <section class="content-header">
                    @yield('content-header')
                </section>
                <section class="content">
                    <div class="row">
                        <div class="col-xs-12">
                            @if (count($errors) > 0)
                                <div class="alert alert-danger">
                                    There was an error validating the data provided.<br><br>
                                    <ul>
                                        @foreach ($errors->all() as $error)
                                            <li>{{ $error }}</li>
                                        @endforeach
                                    </ul>
                                </div>
                            @endif
                            @foreach (Alert::getMessages() as $type => $messages)
                                @foreach ($messages as $message)
                                    <div class="alert alert-{{ $type }} alert-dismissable" role="alert">
                                        {!! $message !!}
                                    </div>
                                @endforeach
                            @endforeach
                        </div>
                    </div>
                    @yield('content')
                </section>
            </div>
            <footer class="main-footer">
                <div class="pull-right small text-gray" style="margin-right:10px;margin-top:-7px;">
                    <strong><i class="fa fa-fw {{ $appIsGit ? 'fa-git-square' : 'fa-code-fork' }}"></i></strong> {{ $appVersion }}<br />
                    <strong><i class="fa fa-fw fa-clock-o"></i></strong> {{ round(microtime(true) - LARAVEL_START, 3) }}s
                </div>
                Copyright &copy; 2015 - {{ date('Y') }} <a href="https://pterodactyl.io/">Pterodactyl Software</a>.
            </footer>
        </div>
        @section('footer-scripts')
            <script src="/js/keyboard.polyfill.js" type="application/javascript"></script>
            <script>keyboardeventKeyPolyfill.polyfill();</script>

            {!! Theme::js('vendor/jquery/jquery.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/sweetalert/sweetalert.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/bootstrap/bootstrap.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/slimscroll/jquery.slimscroll.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/adminlte/app.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/bootstrap-notify/bootstrap-notify.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/select2/select2.full.min.js?t={cache-version}') !!}
            {!! Theme::js('js/admin/functions.js?t={cache-version}') !!}
            <script src="/js/autocomplete.js" type="application/javascript"></script>

            @if(Auth::user()->root_admin)
                <script>
                    $('#logoutButton').on('click', function (event) {
                        event.preventDefault();

                        var that = this;
                        swal({
                            title: 'Do you want to log out?',
                            type: 'warning',
                            showCancelButton: true,
                            confirmButtonColor: '#d9534f',
                            cancelButtonColor: '#d33',
                            confirmButtonText: 'Log out'
                        }, function () {
                             $.ajax({
                                type: 'POST',
                                url: '{{ route('auth.logout') }}',
                                data: {
                                    _token: '{{ csrf_token() }}'
                                },complete: function () {
                                    window.location.href = '{{route('auth.login')}}';
                                }
                        });
                    });
                });
                </script>
            @endif

            <script>
                $(function () {
                    $('[data-toggle="tooltip"]').tooltip();
                })
            </script>
        @show
    </body>
</html>
EOF

    # Set permissions
    chown -R www-data:www-data "$PTERO_DIR/resources/views/layouts"
    chmod 644 "$PTERO_DIR/resources/views/layouts/admin.blade.php"
    
    clear_cache
    
    echo
    echo "============================================================="
    echo -e "${GREEN}✅ HIDE MENU BERJAYI DIPASANG!${NC}"
    echo "============================================================="
    echo -e "${YELLOW}Menu berikut hanya nampak untuk user ID 1:${NC}"
    echo "  • Settings"
    echo "  • Application API"
    echo "  • Databases"
    echo "  • Locations"
    echo "  • Nodes"
    echo "  • Mounts"
    echo "  • Nests"
    echo
    echo -e "${GREEN}User ID 1: Nampak semua menu${NC}"
    echo -e "${YELLOW}User ID lain: Menu di atas tak nampak${NC}"
    echo "============================================================="
}

# ============= UNINSTALL HIDE MENU =============
uninstall_hide_menu() {
    header "UNINSTALL HIDE MENU"
    
    check_pterodactyl
    
    # Restore from backup
    if [ -f "$BACKUP_DIR/admin.blade.php" ]; then
        cp "$BACKUP_DIR/admin.blade.php" "$PTERO_DIR/resources/views/layouts/admin.blade.php"
        log "Restored admin.blade.php from backup"
    else
        # Download fresh copy
        curl -s -o "$PTERO_DIR/resources/views/layouts/admin.blade.php" \
            "https://raw.githubusercontent.com/pterodactyl/panel/develop/resources/views/layouts/admin.blade.php"
        log "Downloaded fresh admin.blade.php"
    fi
    
    clear_cache
    log "Hide Menu has been uninstalled"
}

# ============= FIX ERROR 500 =============
fix_error_500() {
    header "🔧 FIX ERROR 500 PANEL"
    
    check_pterodactyl
    
    warn "Proses ini akan cuba membetulkan panel yang error 500"
    read -p "Teruskan? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Dibatalkan"
        return
    fi
    
    process "Membetulkan syntax error..."
    
    # Fix routes
    [ -f "$PTERO_DIR/routes/admin.php" ] && sed -i 's/->middleware(\[.*\])//g' "$PTERO_DIR/routes/admin.php"
    [ -f "$PTERO_DIR/routes/api-application.php" ] && sed -i 's/->middleware(\[.*\])//g' "$PTERO_DIR/routes/api-application.php"
    
    # Fix Kernel
    [ -f "$PTERO_DIR/app/Http/Kernel.php" ] && sed -i "/'custom.security'/d" "$PTERO_DIR/app/Http/Kernel.php"
    
    clear_cache
    
    # Reset permissions
    chown -R www-data:www-data "$PTERO_DIR"
    chmod -R 755 "$PTERO_DIR/storage" "$PTERO_DIR/bootstrap/cache"
    
    log "✅ Fix selesai! Cuba refresh panel."
}

# ============= RESTORE FROM BACKUP =============
restore_from_backup() {
    header "RESTORE FROM BACKUP"
    
    # Cari backup
    BACKUPS=($(ls -d /root/pterodactyl-backup-* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        warn "Tiada backup dijumpai"
        return
    fi
    
    echo "Senarai backup:"
    for i in "${!BACKUPS[@]}"; do
        echo "[$((i+1))] ${BACKUPS[$i]}"
    done
    echo
    read -p "Pilih backup (1-${#BACKUPS[@]}): " choice
    
    if [[ "$choice" -gt 0 && "$choice" -le "${#BACKUPS[@]}" ]]; then
        SELECTED="${BACKUPS[$((choice-1))]}"
        
        process "Restoring from $SELECTED..."
        
        # Restore all files
        [ -f "$SELECTED/ApiController.php" ] && cp "$SELECTED/ApiController.php" "$PTERO_DIR/app/Http/Controllers/Api/Application/"
        [ -f "$SELECTED/api-application.php" ] && cp "$SELECTED/api-application.php" "$PTERO_DIR/routes/"
        [ -f "$SELECTED/Kernel.php" ] && cp "$SELECTED/Kernel.php" "$PTERO_DIR/app/Http/"
        [ -f "$SELECTED/admin.blade.php" ] && cp "$SELECTED/admin.blade.php" "$PTERO_DIR/resources/views/layouts/"
        
        clear_cache
        log "✅ Restore selesai!"
    fi
}

# ============= SHOW MENU =============
show_menu() {
    clear
    echo "============================================================="
    echo "              PTERODACTYL SECURITY INSTALLER"
    echo "                    Created by Veyora"
    echo "============================================================="
    echo
    echo "Pilih option:"
    echo "[1] 🔒 PROTECT APPLICATION API (PTLA) - Target Class Error"
    echo "[2] 🔓 UNINSTALL PROTECT APPLICATION API"
    echo "[3] 🎨 INSTALL HIDE MENU"
    echo "[4] 🗑️ UNINSTALL HIDE MENU"
    echo "[5] 🔧 FIX ERROR 500"
    echo "[6] 📦 RESTORE FROM BACKUP"
    echo "[7] ❌ EXIT"
    echo
    read -p "Select [1-7]: " choice
    
    case $choice in
        1)
            install_protect_ptla
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        2)
            uninstall_protect_ptla
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        3)
            install_hide_menu
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        4)
            uninstall_hide_menu
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        5)
            fix_error_500
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        6)
            restore_from_backup
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        7)
            exit 0
            ;;
        *)
            warn "Pilihan tak valid! Sila pilih 1-7"
            sleep 2
            show_menu
            ;;
    esac
}

# ============= START =============
if [[ $EUID -ne 0 ]]; then
    error "Script ini mesti run sebagai root! Guna: sudo bash $0"
fi

show_menu
