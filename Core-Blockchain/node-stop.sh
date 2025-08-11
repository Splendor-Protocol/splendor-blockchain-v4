#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color
CYAN='\033[0;36m'
BASE_DIR="/root/splendor-blockchain-v4/Core-Blockchain"

#########################################################################
totalRpc=0
totalValidator=0
totalNodes=$(($totalRpc + $totalValidator))

isRPC=false
isValidator=false

#########################################################################
source ./.env
#########################################################################

#+-----------------------------------------------------------------------------------------------+
#|                                                                                                                             |
#|                                                                                                                             |
#|                                                      FUNCTIONS                                                |
#|                                                                                                                             |
#|                                                                                                                             |
#+-----------------------------------------------------------------------------------------------+

#Logger setup

log_step() {
  echo -e "${CYAN}➜ ${GREEN}$1${NC}"
}

log_success() {
  echo -e "${GREEN}✔ $1${NC}"
}

log_error() {
  echo -e "${RED}✖ $1${NC}"
}

log_wait() {
  echo -e "${CYAN}🕐 $1...${NC}"
}

progress_bar() {
  echo -en "${CYAN}["
  for i in {1..60}; do
    echo -en "#"
    sleep 0.01
  done
  echo -e "]${NC}"
}


countNodes(){
  local i=1
  totalNodes=$(ls -l ./chaindata/ | grep -c ^d)
  while [[ $i -le $totalNodes ]]; do
    
    if [ -f "./chaindata/node$i/.rpc" ]; then  
      ((totalRpc += 1))
    else  
        if [ -f "./chaindata/node$i/.validator" ]; then
        ((totalValidator += 1))
        fi
    fi  
    
    ((i += 1))
  done 
}

stopNode(){
  local session=$1
  local nodePath="$BASE_DIR/chaindata/$session"
  
  if tmux has-session -t "$session" 2>/dev/null; then
    tmux send-keys -t "$session" "exit" Enter
    sleep 2

    # Check if the geth.ipc file exists after stopping the node
    if [ -e "$nodePath/geth.ipc" ]; then
      log_wait "Node $session did not stop gracefully. Retrying..."
      # echo -e "${ORANGE}Node $session did not stop gracefully. Retrying...${NC}"
      tmux send-keys -t "$session" "exit" Enter
      sleep 2
    fi

    # Final check
    if [ -e "$nodePath/geth.ipc" ]; then
      log_error "Node $session is still running. Killing tmux session..."
      # echo -e "${RED}Node $session is still running. Killing tmux session...${NC}"
      tmux kill-session -t "$session"
    else
      log_success "Node $session stopped successfully."
      # echo -e "${GREEN}Node $session stopped successfully.${NC}"
      tmux kill-session -t "$session"
    fi
  else
    log_error "Session $session does not exist."
    # echo -e "${RED}Session $session does not exist.${NC}"
  fi
}

stopRpc(){
  i=$((totalValidator + 1))
  while [[ $i -le $totalNodes ]]; do
    stopNode "node$i"
    ((i += 1))
  done 
}

stopValidator(){
  i=1
  while [[ $i -le $totalValidator ]]; do
    stopNode "node$i"
    ((i += 1))
  done 
}

finalize(){
  pm2 stop all
  countNodes
  
  if [ "$isRPC" = true ]; then
    log_wait "Stopping RPC" && progress_bar
    # echo -e "\n${GREEN}+------------------- Stopping RPC -------------------+"
    stopRpc
  fi

  if [ "$isValidator" = true ]; then
    log_wait "Stopping Validato nodes" && progress_bar
    # echo -e "\n${GREEN}+------------------- Stopping Validator -------------------+"
    stopValidator
  fi

  log_wait "Active Nodes"
  # echo -e "\n${GREEN}+------------------ Active Nodes -------------------+"
  tmux ls || log_error "No active tmux sessions found"
  # tmux ls || echo -e "${RED}No active tmux sessions found.${NC}"
  echo -e "\n${GREEN}+------------------ Active Nodes -------------------+${NC}"
  log_success "Active Nodes"
}

# Default variable values
verbose_mode=false
output_file=""

# Function to display script usage
usage() {
  echo -e "\nUsage: $0 [OPTIONS]"
  echo "Options:"
  echo -e "\t\t -h, --help      Display this help message"
  echo -e " \t\t -v, --verbose   Enable verbose mode"
  echo -e "\t\t --rpc       Stop all the RPC nodes installed"
  echo -e "\t\t --validator       Stop all the Validator nodes installed"
}

has_argument() {
  [[ ("$1" == *=* && -n ${1#*=}) || (! -z "$2" && "$2" != -*) ]]
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in

    # display help
    -h | --help)
      usage
      exit 0
      ;;

    # toggle verbose
    -v | --verbose)
      verbose_mode=true
      ;;

    # take file input
    -f | --file*)
      if ! has_argument $@; then
        echo "File not specified." >&2
        usage
        exit 1
      fi

      output_file=$(extract_argument $@)

      shift
      ;;

    # take ROC count
    --rpc)
        isRPC=true
      ;;

    # take validator count
    --validator)
        isValidator=true
      ;;

    *)
      echo "Invalid option: $1" >&2
      usage
      exit 1
      ;;

    esac
    shift
  done
}

# Main script execution
handle_options "$@"

# Perform the desired actions based on the provided flags and arguments
if [ "$verbose_mode" = true ]; then
  echo "Verbose mode enabled."
fi

if [ -n "$output_file" ]; then
  echo "Output file specified: $output_file"
fi

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    usage
    exit 1
fi

finalize
