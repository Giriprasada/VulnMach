#!/bin/bash
# ================================================================
# VulnCorp Lab — One-Command Deployment Script
# ================================================================
# Run this on a fresh Linux machine (Ubuntu/Debian recommended)
# to get the entire lab running and accessible from the internet.
#
# USAGE:
#   chmod +x deploy.sh
#   sudo ./deploy.sh                         # Interactive (prompts for ngrok token)
#   sudo NGROK_AUTHTOKEN=xxx ./deploy.sh     # Unattended
#
# REQUIREMENTS:
#   - Linux (Ubuntu 20.04+ / Debian 11+ recommended)
#   - Root or sudo access
#   - Internet connection
#
# ⚠️  FOR EDUCATIONAL / LAB USE ONLY — NEVER USE IN PRODUCTION
# ================================================================

set -e

# ── Colors ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║   ██╗   ██╗██╗   ██╗██╗     ███╗   ██╗ ██████╗ ██████╗  ║"
    echo "║   ██║   ██║██║   ██║██║     ████╗  ██║██╔════╝██╔═══██╗ ║"
    echo "║   ██║   ██║██║   ██║██║     ██╔██╗ ██║██║     ██║   ██║ ║"
    echo "║   ╚██╗ ██╔╝██║   ██║██║     ██║╚██╗██║██║     ██║   ██║ ║"
    echo "║    ╚████╔╝ ╚██████╔╝███████╗██║ ╚████║╚██████╗╚██████╔╝ ║"
    echo "║     ╚═══╝   ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ║"
    echo "║                                                          ║"
    echo "║            Vulnerable Lab — Deployment Script            ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info()    { echo -e "${GREEN}[+]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_step()    { echo -e "${BOLD}${CYAN}[*]${NC} $1"; }

# ── Pre-flight checks ────────────────────────────────────────────

print_banner

if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Step 1: Install Docker ───────────────────────────────────────

install_docker() {
    OFFLINE_SCRIPT=""
    for candidate in "$SCRIPT_DIR/offline_installer/install_offline_docker.sh" \
                     "$SCRIPT_DIR/../offline_installer/install_offline_docker.sh" \
                     "/opt/offline_installer/install_offline_docker.sh"; do
        if [ -f "$candidate" ]; then
            OFFLINE_SCRIPT="$candidate"
            break
        fi
    done

    if command -v docker &> /dev/null; then
        log_info "Docker is already installed: $(docker --version)"
        if [ -n "$OFFLINE_SCRIPT" ]; then
            # Still load any offline image tarballs if present
            bash "$OFFLINE_SCRIPT" || true
        fi
        return 0
    fi

    log_step "Installing Docker..."

    if [ -n "$OFFLINE_SCRIPT" ]; then
        log_info "Found offline Docker installer at: $OFFLINE_SCRIPT"
        log_step "Running 100% offline Docker & Compose installation..."
        bash "$OFFLINE_SCRIPT"
        return 0
    fi

    # Detect distro for online fallback
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO="unknown"
    fi

    case $DISTRO in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y -qq ca-certificates curl gnupg lsb-release

            # Add Docker's official GPG key
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" | \
                gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg

            # Add the repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
                https://download.docker.com/linux/$DISTRO \
                $(lsb_release -cs) stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null

            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        centos|rhel|fedora|rocky|alma)
            dnf install -y dnf-plugins-core || yum install -y yum-utils
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || \
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || \
                yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *)
            log_warn "Unsupported distro '$DISTRO'. Trying Docker convenience script..."
            curl -fsSL https://get.docker.com | sh
            ;;
    esac

    systemctl start docker 2>/dev/null || true
    systemctl enable docker 2>/dev/null || true
    log_info "Docker installed successfully"
}

# ── Step 2: Install docker-compose (standalone, if needed) ────────

install_docker_compose() {
    # Check if 'docker compose' (plugin) works
    if docker compose version &> /dev/null; then
        log_info "Docker Compose (plugin) is available: $(docker compose version)"
        COMPOSE_CMD="docker compose"
        return 0
    fi

    # Check standalone docker-compose
    if command -v docker-compose &> /dev/null; then
        log_info "docker-compose is available: $(docker-compose --version)"
        COMPOSE_CMD="docker-compose"
        return 0
    fi

    log_step "Installing docker-compose..."
    OFFLINE_SCRIPT=""
    for candidate in "$SCRIPT_DIR/offline_installer/install_offline_docker.sh" \
                     "$SCRIPT_DIR/../offline_installer/install_offline_docker.sh" \
                     "/opt/offline_installer/install_offline_docker.sh"; do
        if [ -f "$candidate" ]; then
            OFFLINE_SCRIPT="$candidate"
            break
        fi
    done

    if [ -n "$OFFLINE_SCRIPT" ]; then
        log_info "Running offline Compose installer..."
        bash "$OFFLINE_SCRIPT"
        if docker compose version &> /dev/null; then COMPOSE_CMD="docker compose"; return 0; fi
        if command -v docker-compose &> /dev/null; then COMPOSE_CMD="docker-compose"; return 0; fi
    fi

    log_step "Installing docker-compose (standalone online fallback)..."
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d'"' -f4 || echo "v2.27.0")
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    COMPOSE_CMD="docker-compose"
    log_info "docker-compose installed: $($COMPOSE_CMD --version)"
}

# ── Step 3: Install ngrok ────────────────────────────────────────

install_ngrok() {
    if command -v ngrok &> /dev/null; then
        log_info "ngrok is already installed: $(ngrok version)"
        return 0
    fi

    log_step "Installing ngrok..."

    # Use ngrok's official install script
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
        tee /etc/apt/trusted.gpg.d/ngrok.asc > /dev/null

    if command -v apt-get &> /dev/null; then
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
            tee /etc/apt/sources.list.d/ngrok.list
        apt-get update -qq
        apt-get install -y -qq ngrok
    else
        # Fallback: download binary directly
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)  NGROK_ARCH="amd64" ;;
            aarch64) NGROK_ARCH="arm64" ;;
            armv7l)  NGROK_ARCH="arm" ;;
            *)       log_error "Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        curl -sSL "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v2-stable-linux-${NGROK_ARCH}.tgz" | \
            tar xz -C /usr/local/bin
    fi

    log_info "ngrok installed: $(ngrok version)"
}

# ── Step 4: Configure ngrok ──────────────────────────────────────

configure_ngrok() {
    if [ -z "$NGROK_AUTHTOKEN" ]; then
        echo ""
        log_warn "ngrok requires a free auth token."
        echo -e "  ${CYAN}1.${NC} Sign up at ${BOLD}https://dashboard.ngrok.com/signup${NC}"
        echo -e "  ${CYAN}2.${NC} Copy your authtoken from ${BOLD}https://dashboard.ngrok.com/get-started/your-authtoken${NC}"
        echo ""
        read -p "  Enter your ngrok authtoken: " NGROK_AUTHTOKEN

        if [ -z "$NGROK_AUTHTOKEN" ]; then
            log_error "No authtoken provided. ngrok tunnels will not work."
            log_warn "You can still access the lab on the server's LAN IP."
            return 1
        fi
    fi

    ngrok config add-authtoken "$NGROK_AUTHTOKEN"
    log_info "ngrok configured with authtoken"

    # Save the token for the tunnel script
    echo "$NGROK_AUTHTOKEN" > "$SCRIPT_DIR/.ngrok_token"
    chmod 600 "$SCRIPT_DIR/.ngrok_token"
    return 0
}

# ── Step 5: Build and start the lab ──────────────────────────────

start_lab() {
    log_step "Building VulnCorp Docker image..."
    cd "$SCRIPT_DIR"
    $COMPOSE_CMD build

    log_step "Starting VulnCorp lab..."
    $COMPOSE_CMD up -d

    # Wait for the container to be healthy
    log_info "Waiting for services to start..."
    sleep 5

    # Verify the container is running
    if $COMPOSE_CMD ps | grep -q "Up\|running"; then
        log_info "VulnCorp container is running"
    else
        log_error "Container failed to start. Check logs with: $COMPOSE_CMD logs"
        exit 1
    fi
}

# ── Step 6: Start ngrok tunnels ──────────────────────────────────

start_tunnels() {
    log_step "Starting ngrok tunnels..."

    # Kill any existing ngrok processes
    pkill ngrok 2>/dev/null || true
    sleep 1

    # Write ngrok config with multiple tunnels
    NGROK_CONFIG_DIR="$(ngrok config check 2>&1 | grep -oP '(?<=at ).*(?=is valid)' | xargs dirname 2>/dev/null)" || true

    if [ -z "$NGROK_CONFIG_DIR" ]; then
        NGROK_CONFIG_DIR="$HOME/.config/ngrok"
    fi

    mkdir -p "$NGROK_CONFIG_DIR"

    # Create a tunnel config file specifically for VulnCorp
    cat > "$SCRIPT_DIR/ngrok-vulncorp.yml" << NEOF
version: 2
tunnels:
  vulncorp-web:
    proto: http
    addr: 8080
    inspect: false
  vulncorp-ftp:
    proto: tcp
    addr: 2121
NEOF

    # Start ngrok with the tunnel config
    ngrok start --config "$(ngrok config check 2>&1 | grep -oP '(?<=at ).*(?=is valid)')" \
                --config "$SCRIPT_DIR/ngrok-vulncorp.yml" \
                --all &

    NGROK_PID=$!
    echo "$NGROK_PID" > "$SCRIPT_DIR/.ngrok_pid"

    # Wait for tunnels to establish
    sleep 3

    # Get the public URLs from ngrok API
    log_info "Fetching tunnel URLs..."
    sleep 2

    TUNNELS=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)

    if [ -z "$TUNNELS" ] || [ "$TUNNELS" = "null" ]; then
        log_warn "Could not fetch tunnel URLs from ngrok API."
        log_warn "Check manually: http://localhost:4040"
    else
        WEB_URL=$(echo "$TUNNELS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data.get('tunnels', []):
    if 'web' in t.get('name','').lower() or t.get('proto') == 'https':
        print(t['public_url'])
        break
" 2>/dev/null || echo "")

        FTP_URL=$(echo "$TUNNELS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data.get('tunnels', []):
    if 'ftp' in t.get('name','').lower() or (t.get('proto') == 'tcp' and '2121' in str(t.get('config',{}).get('addr',''))):
        print(t['public_url'])
        break
" 2>/dev/null || echo "")

        # Save URLs to file
        cat > "$SCRIPT_DIR/.tunnel_urls" << EOF
WEB_URL=$WEB_URL
FTP_URL=$FTP_URL
EOF
    fi
}

# ── Step 7: Print summary ────────────────────────────────────────

print_summary() {
    # Get server's LAN IP
    LAN_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")

    # Read saved tunnel URLs
    WEB_URL=""
    FTP_URL=""
    if [ -f "$SCRIPT_DIR/.tunnel_urls" ]; then
        source "$SCRIPT_DIR/.tunnel_urls"
    fi

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   ${GREEN}${BOLD}VulnCorp Lab is RUNNING and ACCESSIBLE!${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}🌐 PUBLIC ACCESS (via ngrok):${NC}                           ${CYAN}║${NC}"

    if [ -n "$WEB_URL" ]; then
        echo -e "${CYAN}║${NC}   Web Portal:  ${GREEN}${WEB_URL}${NC}"
    fi
    if [ -n "$FTP_URL" ]; then
        echo -e "${CYAN}║${NC}   FTP Server:  ${GREEN}${FTP_URL}${NC}"
    fi

    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}🏠 LAN ACCESS (same network):${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Web Portal:  ${GREEN}http://${LAN_IP}:8080${NC}"
    echo -e "${CYAN}║${NC}   SSH:         ${GREEN}ssh webuser@${LAN_IP} -p 2222${NC}"
    echo -e "${CYAN}║${NC}   FTP:         ${GREEN}ftp ${LAN_IP} 2121${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}📊 ngrok Dashboard:${NC}  ${GREEN}http://localhost:4040${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}🔑 Credentials:${NC}                                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   SSH:   webuser / webuser123                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Web:   admin / admin@vulncorp2024                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   FTP:   anonymous (no password)                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}   ${RED}⚠️  FOR EDUCATIONAL / LAB USE ONLY${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Management Commands:${NC}"
    echo -e "    Stop lab:        ${CYAN}$COMPOSE_CMD down${NC}"
    echo -e "    View logs:       ${CYAN}$COMPOSE_CMD logs -f${NC}"
    echo -e "    Restart tunnels: ${CYAN}sudo ./tunnel.sh${NC}"
    echo -e "    Destroy lab:     ${CYAN}$COMPOSE_CMD down --rmi all --volumes${NC}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────────────

main() {
    install_docker
    install_docker_compose
    install_ngrok

    NGROK_OK=false
    if configure_ngrok; then
        NGROK_OK=true
    fi

    start_lab

    if $NGROK_OK; then
        start_tunnels
    fi

    print_summary
}

main "$@"
