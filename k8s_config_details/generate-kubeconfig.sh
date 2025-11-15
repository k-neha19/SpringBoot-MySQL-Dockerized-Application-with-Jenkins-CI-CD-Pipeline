#!/bin/bash
################################################################################
# Script: generate-kubeconfig.sh
# Purpose: Generate kubeconfig file for Jenkins automation
# Designed and Developed by: sak_shetty
# Execute this script on the Kubernetes Control Plane node
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

# ---------------------------- Variables --------------------------------------
OUTPUT_DIR="/home/ubuntu/kubeconfig_for_jenkins"
KUBECONFIG_FILE="$OUTPUT_DIR/kubeconfig.yaml"
SRC_FILE="/etc/kubernetes/admin.conf"

# ---------------------------- Main Script ------------------------------------
log_info "Creating output directory: $OUTPUT_DIR"
sudo mkdir -p "$OUTPUT_DIR"

log_info "Copying kubeconfig from $SRC_FILE to $KUBECONFIG_FILE..."
if sudo cp "$SRC_FILE" "$KUBECONFIG_FILE"; then
    sudo chown ubuntu:ubuntu "$KUBECONFIG_FILE"
    sudo chmod 600 "$KUBECONFIG_FILE"
    log_success "Kubeconfig successfully saved at: $KUBECONFIG_FILE"
else
    log_error "Failed to copy kubeconfig!"
    exit 1
fi

# Verify cluster connection
log_info "Verifying Kubernetes cluster connection..."
sudo -u ubuntu kubectl --kubeconfig="$KUBECONFIG_FILE" get nodes || {
    log_error "Unable to verify cluster connection. Please check kubeadm setup."
    exit 1
}

# ---------------------------- Footer Instructions -----------------------------
log_success "Kubeconfig generation completed successfully."
echo "========================================================="
echo "File created at: $KUBECONFIG_FILE"
echo "========================================================="
echo "On Jenkins Server: Before executing this file fetch-and-prepare-kubeconfig.sh"
echo "Edit the variables at the top of fetch-and-prepare-kubeconfig.sh:"
log_info "CONTROL_PLANE_IP → your kubeadm master Private IP"
log_info "CONTROL_PLANE_USER → the SSH user as a control plane user (default: ubuntu)"
log_info "PEM_KEY_PATH → path to your PEM key file to access the control plane"
log_info "Create pem file of a controll plane server on Jenkins server if not already done."
log_info "create pem in this path /root/sak.pem or change the path accordingly in fetch-and-prepare-kubeconfig.sh"
echo "========================================================="
echo "Next Step (on Jenkins Server):"
echo "Run your jen_kube.sh script to fetch and prepare kubeconfig."
echo "========================================================="

################################################################################
# End of Script
# Designed and Developed by: sak_shetty
################################################################################
