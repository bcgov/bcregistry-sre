#!/bin/bash
# Terraform workspace helper script
# Usage: ./tf.sh <command> [workspace] [extra args]
#
# Commands:
#   plan [workspace]     - Run plan for one or all workspaces
#   apply [workspace]    - Run apply for one or all workspaces
#   status               - Show resource count per workspace
#   list                 - List all workspaces
#
# Examples:
#   ./tf.sh plan dev           # Plan dev only
#   ./tf.sh plan all           # Plan all workspaces
#   ./tf.sh apply prod         # Apply prod only
#   ./tf.sh status             # Show status of all workspaces

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment
if [[ -f .env ]]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

WORKSPACES=("default" "dev" "test" "prod" "other")

usage() {
    echo "Usage: $0 <command> [workspace] [extra args]"
    echo ""
    echo "Commands:"
    echo "  plan [workspace]   - Run terraform plan (workspace: dev|test|prod|other|default|all)"
    echo "  apply [workspace]  - Run terraform apply (workspace: dev|test|prod|other|default|all)"
    echo "  status             - Show resource count per workspace"
    echo "  list               - List all workspaces"
    echo ""
    echo "Examples:"
    echo "  $0 plan dev        # Plan dev only"
    echo "  $0 plan all        # Plan all workspaces"
    echo "  $0 apply prod      # Apply prod only"
    echo "  $0 status          # Show status"
    exit 1
}

run_for_workspace() {
    local ws=$1
    local cmd=$2
    shift 2
    local extra_args="$@"
    
    echo -e "\n${BLUE}=== Workspace: $ws ===${NC}"
    terraform workspace select "$ws" >/dev/null 2>&1
    
    case $cmd in
        plan)
            terraform plan -refresh=false $extra_args
            ;;
        apply)
            terraform apply $extra_args
            ;;
        status)
            count=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
            echo -e "Resources: ${GREEN}$count${NC}"
            ;;
    esac
}

run_for_all() {
    local cmd=$1
    shift
    local extra_args="$@"
    
    for ws in "${WORKSPACES[@]}"; do
        run_for_workspace "$ws" "$cmd" $extra_args
    done
}

# Main
if [[ $# -lt 1 ]]; then
    usage
fi

CMD=$1
WS=${2:-""}
shift
[[ $# -gt 0 ]] && shift
EXTRA_ARGS="$@"

case $CMD in
    plan|apply)
        if [[ -z "$WS" ]]; then
            echo -e "${RED}Error: Specify workspace (dev|test|prod|other|default|all)${NC}"
            exit 1
        fi
        
        if [[ "$WS" == "all" ]]; then
            run_for_all "$CMD" $EXTRA_ARGS
        else
            run_for_workspace "$WS" "$CMD" $EXTRA_ARGS
        fi
        ;;
    status)
        echo -e "${BLUE}Workspace Status${NC}"
        echo "----------------"
        for ws in "${WORKSPACES[@]}"; do
            terraform workspace select "$ws" >/dev/null 2>&1
            count=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
            printf "%-10s %s\n" "$ws:" "$count resources"
        done
        ;;
    list)
        terraform workspace list
        ;;
    *)
        usage
        ;;
esac

echo -e "\n${GREEN}Done${NC}"
