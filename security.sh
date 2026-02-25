#!/bin/bash

# ============================================
# Pterodactyl Security Installer - WITH DEFACE
# Author: Veyora (@vdnox)
# Version: 11.0 - Deface Application API
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
VERSION="11.0"

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
    
    # Backup files yang akan diubah
    [ -f "$PTERO_DIR/resources/views/layouts/admin.blade.php" ] && \
        cp "$PTERO_DIR/resources/views/layouts/admin.blade.php" "$BACKUP_DIR/"
    
    [ -f "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php" ] && \
        cp "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php" "$BACKUP_DIR/"
    
    log "Backup created at $BACKUP_DIR"
    info "Backup location: $BACKUP_DIR"
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

# ============= INSTALL DEFACE APPLICATION API =============
install_deface_api() {
    header="🚫 DEFACE APPLICATION API - Pemasangan"
    
    check_pterodactyl
    backup_files
    
    show_loading "Memasang Deface untuk Application API"
    
    # Create directory if not exists
    mkdir -p "$PTERO_DIR/app/Http/Controllers/Api/Application"
    
    # Write the controller with deface
    cat > "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Application;

use Illuminate\Http\Request;
use Pterodactyl\Http\Controllers\Api\Application\ApplicationApiController;

class ApiController extends ApplicationApiController
{
    /**
     * Display a listing of the API credentials.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Kalau user ID 1, bagi view normal
        if ($user && $user->id == 1) {
            return view('admin.api.index');
        }
        
        // Kalau bukan ID 1, bagi page deface
        return $this->defacePage();
    }
    
    /**
     * Show the form for creating new API credentials.
     */
    public function create(Request $request)
    {
        $user = $request->user();
        
        // Kalau user ID 1, bagi view normal
        if ($user && $user->id == 1) {
            return view('admin.api.create');
        }
        
        // Kalau bukan ID 1, bagi page deface
        return $this->defacePage();
    }
    
    /**
     * Show the form for editing API credentials.
     */
    public function edit(Request $request, $id)
    {
        $user = $request->user();
        
        // Kalau user ID 1, bagi view normal
        if ($user && $user->id == 1) {
            return view('admin.api.edit');
        }
        
        // Kalau bukan ID 1, bagi page deface
        return $this->defacePage();
    }
    
    /**
     * Display deface page for unauthorized users
     */
    private function defacePage()
    {
        $html = '
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🔒 ACCESS DENIED - Veyora Security</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 0;
            padding: 20px;
            position: relative;
            overflow: hidden;
        }
        
        body::before {
            content: "";
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: repeating-linear-gradient(
                45deg,
                transparent,
                transparent 10px,
                rgba(255, 255, 255, 0.03) 10px,
                rgba(255, 255, 255, 0.03) 20px
            );
            animation: moveBg 20s linear infinite;
        }
        
        @keyframes moveBg {
            0% { transform: translate(0, 0) rotate(0deg); }
            100% { transform: translate(10%, 10%) rotate(5deg); }
        }
        
        .container {
            max-width: 700px;
            width: 100%;
            position: relative;
            z-index: 1;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 30px;
            padding: 50px;
            box-shadow: 0 30px 70px rgba(0, 0, 0, 0.5);
            text-align: center;
            position: relative;
            overflow: hidden;
            border: 2px solid rgba(255, 255, 255, 0.2);
            transform-style: preserve-3d;
            animation: cardFloat 3s ease-in-out infinite;
        }
        
        @keyframes cardFloat {
            0%, 100% { transform: translateY(0) rotateX(0deg); }
            50% { transform: translateY(-10px) rotateX(2deg); }
        }
        
        .card::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 8px;
            background: linear-gradient(90deg, #ff6b6b, #feca57, #48dbfb, #ff9ff3, #f368e0);
            background-size: 300% 100%;
            animation: gradientMove 3s ease infinite;
        }
        
        @keyframes gradientMove {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .icon {
            font-size: 100px;
            margin-bottom: 20px;
            animation: glitch 1s infinite;
            display: inline-block;
        }
        
        @keyframes glitch {
            0%, 100% { transform: skew(0deg, 0deg); opacity: 1; }
            25% { transform: skew(10deg, 5deg) scale(1.1); opacity: 0.9; }
            50% { transform: skew(-10deg, -5deg) scale(0.9); opacity: 0.8; }
            75% { transform: skew(5deg, -5deg) scale(1.05); opacity: 0.9; }
        }
        
        h1 {
            color: #1a1a2e;
            font-size: 48px;
            margin-bottom: 15px;
            font-weight: 900;
            text-transform: uppercase;
            letter-spacing: 3px;
            text-shadow: 3px 3px 0 rgba(255, 107, 107, 0.3);
        }
        
        .glitch-text {
            position: relative;
            display: inline-block;
        }
        
        .glitch-text::before,
        .glitch-text::after {
            content: "ACCESS DENIED";
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0.8;
        }
        
        .glitch-text::before {
            color: #ff6b6b;
            z-index: -1;
            transform: translate(2px, 2px);
            animation: glitchText 3s infinite;
        }
        
        .glitch-text::after {
            color: #4a90e2;
            z-index: -2;
            transform: translate(-2px, -2px);
            animation: glitchText 2.5s infinite reverse;
        }
        
        @keyframes glitchText {
            0%, 100% { transform: translate(0, 0); opacity: 0; }
            10% { transform: translate(3px, 2px); opacity: 0.5; }
            20% { transform: translate(-3px, -2px); opacity: 0.5; }
            30% { transform: translate(2px, -2px); opacity: 0; }
        }
        
        .message {
            color: #4a4a6a;
            font-size: 20px;
            margin-bottom: 30px;
            line-height: 1.6;
            font-weight: 500;
        }
        
        .error-box {
            background: #1a1a2e;
            padding: 25px;
            border-radius: 15px;
            margin-bottom: 30px;
            border: 2px solid #ff6b6b;
            text-align: left;
            box-shadow: inset 0 0 20px rgba(255, 107, 107, 0.3);
        }
        
        .error-box pre {
            margin: 0;
            color: #00ff00;
            font-family: "Courier New", monospace;
            font-size: 13px;
            line-height: 1.5;
            white-space: pre-wrap;
            word-wrap: break-word;
            text-shadow: 0 0 5px rgba(0, 255, 0, 0.5);
        }
        
        .status-badge {
            display: inline-block;
            background: linear-gradient(135deg, #ff6b6b 0%, #feca57 100%);
            color: white;
            padding: 12px 35px;
            border-radius: 50px;
            font-weight: bold;
            font-size: 18px;
            margin-bottom: 25px;
            box-shadow: 0 5px 15px rgba(255, 107, 107, 0.4);
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        
        .warning {
            background: rgba(255, 193, 7, 0.1);
            border-left: 5px solid #ffc107;
            padding: 20px;
            border-radius: 10px;
            margin: 25px 0;
            text-align: left;
        }
        
        .warning p {
            color: #856404;
            font-size: 16px;
            margin: 5px 0;
        }
        
        .warning strong {
            color: #533f03;
        }
        
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px dashed rgba(0, 0, 0, 0.1);
            color: #6c757d;
            font-size: 14px;
        }
        
        .signature {
            color: #ff6b6b;
            font-weight: bold;
            font-size: 18px;
            margin-top: 20px;
            text-transform: uppercase;
            letter-spacing: 3px;
        }
        
        .blink {
            animation: blink 1s step-end infinite;
        }
        
        @keyframes blink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="icon">🔒</div>
            <h1 class="glitch-text">ACCESS DENIED</h1>
            <div class="status-badge">HTTP 403 FORBIDDEN</div>
            
            <div class="message">
                ⚠️ Hanya Admin Utama (ID 1) yang boleh mengakses halaman ini ⚠️
            </div>
            
            <div class="error-box">
                <pre>
Target class [custom.security] does not exist.

## Exception Details
ReflectionException  
BindingResolutionException  

HTTP 500 Internal Server Error  

---

## Stack Trace

Illuminate\Contracts\Container\BindingResolutionException  
in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Container/Container.php (line 914)  

in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Container/Container.php -> build (line 795)  

in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Foundation/Application.php -> resolve (line 963)  

in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Container/Container.php -> resolve (line 731)  

in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Foundation/Application.php -> make (line 948)  

in /var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Pipeline/Pipeline.php -> make (line 172)  

Pipeline->Illuminate\Pipelines\Closure()  
in /var/www/pterodactyl/app/Http/Middleware/AdminAuth/middleware.php (line 211)
                </pre>
            </div>
            
            <div class="warning">
                <p><strong>⚠️ PERHATIAN ⚠️</strong></p>
                <p>• Halaman ini hanya boleh diakses oleh user dengan ID = 1</p>
                <p>• Anda telah dikenalpasti sebagai user ID: <span class="blink">' . ($user->id ?? 'Unknown') . '</span></p>
                <p>• Akses anda telah direkodkan dalam sistem log</p>
            </div>
            
            <div class="footer">
                <p>🔐 Veyora Security System - Panel Protection</p>
                <p>© 2024 - All Rights Reserved</p>
            </div>
            
            <div class="signature">
                # Veyora @vdnox
            </div>
        </div>
    </div>
</body>
</html>
';
        
        return response($html, 403)
            ->header('Content-Type', 'text/html')
            ->header('X-Robots-Tag', 'noindex, nofollow')
            ->header('X-Defaced-By', 'Veyora Security');
    }
}
EOF

    # Set permissions
    chown www-data:www-data "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php"
    chmod 644 "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php"
    
    clear_cache
    
    echo
    echo "============================================================="
    echo -e "${GREEN}✅ DEFACE APPLICATION API BERJAYI DIPASANG!${NC}"
    echo "============================================================="
    echo -e "${YELLOW}HASILNYA:${NC}"
    echo -e "${GREEN}✓ User ID 1: Buka /admin/api → Normal (macam biasa)${NC}"
    echo -e "${RED}✗ User ID 2+: Buka /admin/api → Nampak page DEFACE keren${NC}"
    echo
    echo -e "${CYAN}Deface page termasuk:${NC}"
    echo "  • Error message macam dalam gambar"
    echo "  • Stack trace palsu"
    echo "  • Warning message"
    echo "  • Animasi glitch"
    echo "  • Status 403 Forbidden"
    echo "============================================================="
}

# ============= UNINSTALL DEFACE APPLICATION API =============
uninstall_deface_api() {
    header "UNINSTALL DEFACE APPLICATION API"
    
    check_pterodactyl
    
    # Restore from backup
    if [ -f "$BACKUP_DIR/ApiController.php" ]; then
        cp "$BACKUP_DIR/ApiController.php" "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php"
        log "Restored ApiController.php from backup"
    else
        # Download fresh copy from GitHub
        warn "No backup found. Downloading fresh copy from Pterodactyl repo..."
        curl -s -o "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php" \
            "https://raw.githubusercontent.com/pterodactyl/panel/develop/app/Http/Controllers/Api/Application/ApiController.php"
        log "Downloaded fresh ApiController.php"
    fi
    
    clear_cache
    log "✅ Deface Application API telah diuninstall"
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
        log "Hide Menu has been uninstalled"
    else
        warn "No backup found. Cannot uninstall automatically."
    fi
    
    clear_cache
    log "Hide Menu has been uninstalled"
}

# ============= RESTORE FROM BACKUP =============
restore_from_backup() {
    header "RESTORE FROM BACKUP"
    
    # Cari semua backup
    BACKUPS=($(ls -d /root/pterodactyl-backup-* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        warn "Tiada backup dijumpai di /root/"
        return
    fi
    
    echo "Senarai backup dijumpai:"
    echo
    for i in "${!BACKUPS[@]}"; do
        echo "[$((i+1))] ${BACKUPS[$i]}"
    done
    echo
    read -p "Pilih backup (1-${#BACKUPS[@]}) atau 0 untuk batal: " choice
    
    if [[ "$choice" == "0" ]]; then
        return
    fi
    
    if [[ "$choice" -gt 0 && "$choice" -le "${#BACKUPS[@]}" ]]; then
        SELECTED="${BACKUPS[$((choice-1))]}"
        
        process "Restoring from $SELECTED..."
        
        # Restore admin.blade.php
        if [ -f "$SELECTED/admin.blade.php" ]; then
            cp "$SELECTED/admin.blade.php" "$PTERO_DIR/resources/views/layouts/admin.blade.php"
            log "Restored admin.blade.php"
        fi
        
        # Restore ApiController.php
        if [ -f "$SELECTED/ApiController.php" ]; then
            cp "$SELECTED/ApiController.php" "$PTERO_DIR/app/Http/Controllers/Api/Application/ApiController.php"
            log "Restored ApiController.php"
        fi
        
        clear_cache
        log "✅ Restore selesai!"
    else
        warn "Pilihan tak valid"
    fi
}

# ============= FIX ERROR 500 =============
fix_error_500() {
    header "🔧 FIX ERROR 500 PANEL"
    
    check_pterodactyl
    
    warn "Proses ini akan cuba membetulkan panel yang error 500"
    echo
    
    read -p "Teruskan? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Dibatalkan"
        return
    fi
    
    process "Membetulkan syntax error di routes/admin.php..."
    
    # Backup dulu file yang bermasalah
    [ -f "$PTERO_DIR/routes/admin.php" ] && cp "$PTERO_DIR/routes/admin.php" "$PTERO_DIR/routes/admin.php.error.backup"
    
    # Buang semua middleware yang bermasalah
    sed -i 's/->middleware(\[.*\])//g' "$PTERO_DIR/routes/admin.php"
    sed -i "s/'custom.security'//g" "$PTERO_DIR/routes/admin.php"
    sed -i 's/"custom.security"//g' "$PTERO_DIR/routes/admin.php"
    sed -i 's/,,/,/g' "$PTERO_DIR/routes/admin.php"
    
    # Bersihkan Kernel.php
    if [ -f "$PTERO_DIR/app/Http/Kernel.php" ]; then
        cp "$PTERO_DIR/app/Http/Kernel.php" "$PTERO_DIR/app/Http/Kernel.php.error.backup"
        sed -i "/'custom.security'/d" "$PTERO_DIR/app/Http/Kernel.php"
    fi
    
    clear_cache
    
    # Reset permissions
    chown -R www-data:www-data "$PTERO_DIR"
    chmod -R 755 "$PTERO_DIR/storage" "$PTERO_DIR/bootstrap/cache"
    
    log "✅ Fix selesai! Cuba refresh panel."
}

# ============= SHOW MENU =============
show_menu() {
    clear
    echo "⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣭⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⠤⢤⣀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠴⠒⢋⣉⣀⣠⣄⣀⣈⡇"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣾⣯⠴⠚⠉⠉⠀⠀⠀⠀⣤⠏⣿"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⡇⠁⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⡿⠿⢛⠁⠁⣸⠀⠀⠀⠀⠀⣤⣾⠵⠚⠁"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⢦⡀⠀⣠⠀⡇⢧⠀⠀⢀⣠⡾⡇⠀⠀⠀⠀⠀⣠⣴⠿⠋⠁⠀⠀⠀⠀⠘⣿⠀⣀⡠⠞⠛⠁⠂⠁⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⣻⡦⣞⡿⣷⠸⣄⣡⢾⡿⠁⠀⠀⠀⣀⣴⠟⠋⠁⠀⠀⠀⠀⠐⠠⡤⣾⣙⣶⡶⠃⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣂⡷⠰⣔⣾⣖⣾⡷⢿⣐⣀⣀⣤⢾⣋⠁⠀⠀⠀⣀⢀⣀⣀⣀⣀⠀⢀⢿⠑⠃⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡦⠴⠴⠤⠦⠤⠤⠤⠤⠤⠴⠶⢾⣽⣙⠒⢺⣿⣿⣿⣿⢾⠶⣧⡼⢏⠑⠚⠋⠉⠉⡉⡉⠉⠉⠹⠈⠁⠉⠀⠨⢾⡂⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠀⠂⠐⠀⠀⠀⠈⣇⡿⢯⢻⣟⣇⣷⣞⡛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣆⠀⠀⠀⠀⢠⡷⡛⣛⣼⣿⠟⠙⣧⠅⡄⠀⠀⠀⠀⠀⠀⠰⡆⠀⠀⠀⠀⢠⣾⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⢶⠏⠉⠀⠀⠀⠀⠀⠿⢠⣴⡟⡗⡾⡒⠖⠉⠏⠁⠀⠀⠀⠀⣀⢀⣠⣧⣀⣀⠀⠀⠀⠚⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⢴⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⣠⣷⢿⠋⠁⣿⡏⠅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣿⢭⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⢏⡵⠛⠀⠀⠀⠀⠀⠀⠀⣀⣴⠞⠛⠀⠀⠀⠀⢿⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⢿⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣼⠛⣲⡏⠁⠀⠀⠀⠀⠀⢀⣠⡾⠋⠉⠀⠀⠀⠀⠀⠀⢾⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠟⠀⢰⡯⠄⠀⠀⠀⠀⣠⢴⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠁⠁⠀⠘⠧⠤⢤⣤⠶⠏⠙⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢾⡃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣇⠂⢀⣀⣀⠤⠞⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠾⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢼⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "⠄⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    echo "============================================================="
    echo "                     Panel Protect"
    echo "               Created by Veyora (@vdnox)"
    echo "============================================================="
    echo
    echo "Pilih option:"
    echo "[1] Install Hide Menu (Sembunyi menu dari user biasa)"
    echo "[2] Install Deface Application API (Error page untuk ID selain 1)"
    echo "[3] Uninstall Hide Menu"
    echo "[4] Uninstall Deface Application API"
    echo "[5] 🔧 FIX ERROR 500 PANEL"
    echo "[6] Restore from Backup"
    echo "[7] Exit"
    echo
    read -p "Select [1-7]: " choice
    
    case $choice in
        1) 
            install_hide_menu
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        2)
            install_deface_api
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        3)
            uninstall_hide_menu
            echo
            read -p "Press Enter to return to menu..."
            show_menu
            ;;
        4)
            uninstall_deface_api
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

# ============= START SCRIPT =============
# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "Script ini mesti run sebagai root! Guna: sudo bash security.sh"
fi

# Start menu
show_menu
