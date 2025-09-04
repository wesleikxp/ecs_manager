#!/usr/bin/env bash

# Colors variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
RESET='\033[0m'
BOLD='\033[1m'

# AWS Credentials
PROFILE_HML="hml"
PROFILE_PRD="prd"

# Environment variable
CURRENT_ENVIRONMENT=""
CURRENT_CLUSTER=""
CURRENT_SERVICE=""

menu_principal() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔═══════════════════════════════════════════╗"
  echo "║          WELCOME TO ECS MANAGER           ║"
  echo "║                                           ║"
  echo "║                  by KXP                   ║"
  echo "╚═══════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "Current environment: ${CURRENT_ENVIRONMENT:-${GREEN}Default}${RESET}"
  echo -e "Current cluster: ${CURRENT_CLUSTER:-${GREEN}Default}${RESET}"
  echo -e "Current service: ${CURRENT_SERVICE:-${GREEN}Default}${RESET}"
  echo "---------------------------------------------"
  echo "Select the environment:"
  echo "1) Select environment"
  echo "2) Manager ECS Cluster"
  echo "0) Exit"
  echo "---------------------------------------------"
}

menu_clusters() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔═══════════════════════════════════════════╗"
  echo "║          WELCOME TO ECS MANAGER           ║"
  echo "║                                           ║"
  echo "║                  by KXP                   ║"
  echo "╚═══════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "Current environment: ${CURRENT_ENVIRONMENT:-${GREEN}Default}${RESET}"
  echo -e "Current cluster: ${CURRENT_CLUSTER:-${GREEN}Default}${RESET}"
  echo -e "Current service: ${CURRENT_SERVICE:-${GREEN}Default}${RESET}"
  echo "-------------------------------------------"
  echo "1) List ECS cluster"
  echo "2) List cluster services"
  echo "3) List tasks"
  echo "4) Execute command into container"
  echo "5) Return to principal menu"
  echo "-------------------------------------------"
}

set_profile() {
  case $1 in
  1)
    export AWS_PROFILE=$PROFILE_HML
    CURRENT_ENVIRONMENT="${YELLOW}HML${RESET}"
    CURRENT_CLUSTER=""
    CURRENT_SERVICE=""
    echo -e "${GREEN}[INFO]${RESET} HML credentials successfully configured!"
    ;;
  2)
    export AWS_PROFILE=$PROFILE_PRD
    CURRENT_ENVIRONMENT="${RED}PRD${RESET}"
    CURRENT_CLUSTER="${RED}${RESET}"
    CURRENT_SERVICE="${RED}${RESET}"
    echo -e "${GREEN}[INFO]${RESET} PRD credentials successfully configured!"
    ;;
  *)
    echo "Invalid option."
    ;;
  esac
}

select_cluster() {
  echo -e "${GREEN}[INFO]${RESET} Searching availables cluster..."
  CLUSTERS=($(aws ecs list-clusters --query "clusterArns[]" --output text | sed 's#.*/##g'))

  if [ ${#CLUSTERS[@]} -eq 0 ]; then
    echo -e "${RED}[ERROR]${RESET} No clusters found in $CURRENT_CLUSTER..."
    return
  fi

  echo "------------------------"
  echo "Select a cluster:"
  i=1
  for C in "${CLUSTERS[@]}"; do
    echo "$i) $C"
    ((i++))
  done
  echo "-------------------------"
  read -rp "Enter your option: " IDX

  if [[ $IDX -ge 1 && $IDX -le ${#CLUSTERS[@]} ]]; then
    CURRENT_CLUSTER=${CLUSTERS[$((IDX - 1))]}
    echo -e "${GREEN}[INFO]${RESET} Selected cluster: $CURRENT_CLUSTER"
  else
    echo -e "${RED}[ERROR]${RESET} Invalid option."
  fi
}

select_services() {
  if [ -z "$CURRENT_CLUSTER" ]; then
    echo -e "${RED}[ERROR]${RESET} No cluster seleted!"
    return
  fi

  echo -e "${GREEN}[INFO]${RESET} Searching clusters services $CURRENT_CLUSTER..."
  SERVICES=($(aws ecs list-services --cluster "$CURRENT_CLUSTER" --query "serviceArns[]" --output text | sed 's#.*/##g'))

  if [ ${#SERVICES[@]} -eq 0 ]; then
    echo -e "${RED}[ERROR]${RESET} No service found in the cluster $CURRENT_CLUSTER."
    return
  fi

  echo "-----------------------------------"
  echo "Select a servce:"
  i=1
  for S in "${SERVICES[@]}"; do
    echo "$i) $S"
    ((i++))
  done
  echo "-----------------------------------"
  read -p "Enter your option: " IDX

  if [[ $IDX -ge 1 && $IDX -le ${#SERVICES[@]} ]]; then
    CURRENT_SERVICE=${SERVICES[$((IDX - 1))]}
    echo -e "${GREEN}[INFO]${RESET} Service Selected: $CURRENT_SERVICE"
  else
    echo -e "${RED}[ERROR]${RESET} Invalid option."
  fi
}

list_tasks() {
  if [ -z "$CURRENT_CLUSTER" ] || [ -z "$CURRENT_SERVICE" ]; then
    echo -e "${RED}[ERROR]${RESET} Select a cluster and service first!"
    return
  fi
  echo -e "${GREEN}[INFO]${RESET} Listing tasks for the $CURRENT_SERVICE service in the $CURRENT_CLUSTER cluster..."
  aws ecs list-tasks --cluster "$CURRENT_CLUSTER" --service-name "$CURRENT_SERVICE" --output table
}

ecs_exec() {
  if [ -z "$CURRENT_CLUSTER" ] || [ -z "$CURRENT_SERCICE" ]; then
    echo -e "${RED}[ERROR]${RESET} Select a cluster and service first!"
    return
  fi
  read -p "Digite o ARN ou ID da task: " TASK
  read -p "Digite o nome do container: " CONTAINER
  read -p "Digite o comando para executar: " COMANDO
  echo -e "${GREEN}[INFO]${RESET} Executando comando dentro do container..."
  aws ecs execute-command --cluster "$CURRENT_CLUSTER" --task "$TASK" --container "$CONTAINER" --interactive --command "$COMMAND"
}

submenu_clusters() {
  while true; do
    menu_clusters
    read -rp "Enter your option: " OPTION

    case $OPTION in
    1) select_cluster ;;
    2) select_services ;;
    3) list_tasks ;;
    4) ecs_exec ;;
    5) break ;;
    *) echo "Invalid option." ;;
    esac

    echo ""
    read -rp "Press ENTER to continue..." pause
  done
}

while true; do
  menu_principal
  read -p "Enter your choice: " OPTION

  case $OPTION in
  1)
    echo "Select the environment: "
    echo -e "1) ${YELLOW}HML${RESET}"
    echo -e "2) ${RED}PRD${RESET}"
    read -rp "Enter your option: " ENV
    set_profile $ENV
    ;;
  2) submenu_clusters ;;
  0)
    echo "Exiting..."
    exit 0
    ;;
  *) echo "Invalid option." ;;
  esac

  echo ""
  read -p "Press ENTER to continue..." pause
done
