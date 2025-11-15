#!/bin/bash
################################################################################
# Script: fetch-and-prepare-kubeconfig.sh
# Purpose: Automatically copy kubeconfig from kubeadm control plane and prepare for Jenkins
# Designed and Developed by: sak_shetty
# Execute this script on the Jenkins Server
################################################################################

# ---------------------------- Colors for Logging ------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"; }
log_error()   { echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"; }

# ---------------------------- User Input --------------------------------------
echo -e "${YELLOW}Please provide the following details:${NC}"
read -rp "Enter the SSH user for control plane (default: ubuntu): " CONTROL_PLANE_USER
CONTROL_PLANE_USER=${CONTROL_PLANE_USER:-ubuntu}

read -rp "Enter the control plane PRIVATE IP: " CONTROL_PLANE_IP
if [ -z "$CONTROL_PLANE_IP" ]; then
    log_error "Control plane IP cannot be empty!"
    exit 1
fi

read -rp "Enter PEM_KEY_FILE name from /root/PEM_KEY_FILE (default: /root/sak.pem): " PEM_KEY_PATH

# ---------------------------- Validate PEM Key --------------------------------
if [ ! -f "$PEM_KEY_PATH" ]; then
    log_error "PEM key not found at $PEM_KEY_PATH"
    exit 1
fi

CURRENT_PERM=$(stat -c "%a" "$PEM_KEY_PATH")
if [ "$CURRENT_PERM" != "400" ]; then
    log_info "Fixing permissions for PEM key (was $CURRENT_PERM, setting to 400)..."
    chmod 400 "$PEM_KEY_PATH"
    log_success "PEM key permission set to 400."
fi

# ---------------------------- Variables ---------------------------------------
LOCAL_DEST_DIR="/home/jenkins/kubeconfig_for_jenkins"
LOCAL_KUBECONFIG="$LOCAL_DEST_DIR/kubeconfig.yaml"

# ---------------------------- Check / Install kubectl -------------------------
if command -v kubectl &>/dev/null; then
    KUBECTL_VER=$(kubectl version --client --short 2>/dev/null | awk '{print $3}')
    log_success "kubectl already installed (version: ${KUBECTL_VER:-unknown})."
else
    log_info "kubectl not found. Installing now..."
    sudo apt update -y
    sudo snap install kubectl --classic
    if command -v kubectl &>/dev/null; then
        KUBECTL_VER=$(kubectl version --client --short 2>/dev/null | awk '{print $3}')
        log_success "kubectl installed successfully (version: ${KUBECTL_VER:-unknown})."
    else
        log_error "kubectl installation failed!"
        exit 1
    fi
fi

# ---------------------------- Detect Remote Kubeconfig ------------------------
log_info "Detecting kubeconfig on control plane..."
POSSIBLE_PATHS=(
    "/home/$CONTROL_PLANE_USER/kubeconfig_for_jenkins/kubeconfig.yaml"
    "/home/$CONTROL_PLANE_USER/kubeconfig.yaml"
)

REMOTE_KUBECONFIG=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if ssh -i "$PEM_KEY_PATH" -o StrictHostKeyChecking=no "${CONTROL_PLANE_USER}@${CONTROL_PLANE_IP}" "[ -f $path ]"; then
        REMOTE_KUBECONFIG="$path"
        log_success "Found kubeconfig on control plane: $REMOTE_KUBECONFIG"
        break
    fi
done

if [ -z "$REMOTE_KUBECONFIG" ]; then
    log_error "No kubeconfig found on control plane under expected paths."
    exit 1
fi

# ---------------------------- Copy Kubeconfig ---------------------------------
mkdir -p "$LOCAL_DEST_DIR"

log_info "Copying kubeconfig from control plane ($CONTROL_PLANE_USER@$CONTROL_PLANE_IP)..."
scp -i "$PEM_KEY_PATH" -o StrictHostKeyChecking=no "${CONTROL_PLANE_USER}@${CONTROL_PLANE_IP}:${REMOTE_KUBECONFIG}" "$LOCAL_KUBECONFIG"
if [ $? -ne 0 ]; then
    log_error "Failed to copy kubeconfig from control plane!"
    exit 1
fi
log_success "Kubeconfig copied successfully to $LOCAL_KUBECONFIG"

# ---------------------------- Update IP in Kubeconfig -------------------------
log_info "Updating kubeconfig with provided control plane IP ($CONTROL_PLANE_IP)..."
if grep -q "server:" "$LOCAL_KUBECONFIG"; then
    sed -i "s#server: https://.*:6443#server: https://$CONTROL_PLANE_IP:6443#g" "$LOCAL_KUBECONFIG"
    log_success "Kubeconfig server endpoint updated."
else
    log_error "Failed to find 'server:' entry in kubeconfig!"
    exit 1
fi

# ---------------------------- Secure Permissions ------------------------------
log_info "Setting secure permissions and ownership for kubeconfig..."
sudo chown jenkins:jenkins "$LOCAL_KUBECONFIG"
sudo chmod 600 "$LOCAL_KUBECONFIG"

# Added redundant hardening (ensures ownership and perms are correct)
sudo chown jenkins:jenkins /home/jenkins/kubeconfig_for_jenkins/kubeconfig.yaml
sudo chmod 600 /home/jenkins/kubeconfig_for_jenkins/kubeconfig.yaml

log_success "Ownership set to jenkins:jenkins and permissions to 600."

# ---------------------------- Test Cluster Connectivity -----------------------
export KUBECONFIG="$LOCAL_KUBECONFIG"
log_info "Testing kubectl connectivity..."
if sudo -u jenkins kubectl --kubeconfig="$LOCAL_KUBECONFIG" get nodes &>/dev/null; then
    log_success "Kubectl successfully connected to the cluster!"
else
    log_error "Kubectl cannot connect to the cluster. Check IP, security groups, or cluster status!"
    exit 1
fi

# ---------------------------- Jenkins Instructions ----------------------------
log_success "Kubeconfig ready for Jenkins usage."
echo "================================================================"
echo "File Path: $LOCAL_KUBECONFIG"
echo "Jenkins user already has ownership and permissions to use it."
echo "No need to add as Jenkins credential file — the file is local."
echo "You can now run your Jenkins pipeline normally."
echo "================================================================"

################################################################################
# End of Script
# Designed and Developed by: sak_shetty
################################################################################
