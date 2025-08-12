#!/usr/bin/env bash
#
# A library file containing the load-env shell function.
# This file is intended to be sourced, not executed directly.

function load-env {
  # Define colors for logging
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local RED='\033[0;31m'
  local NC='\033[0m' # No Color

  local env_file="${1:-.env}"

  if [[ ! -f "$env_file" ]]; then
    echo -e "${RED}Error: Environment file not found: $env_file${NC}"
    return 1
  fi

  local count=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" || "$line" =~ ^\s*# ]]; then
      continue
    fi
    line="${line#export }"
    local key="${line%%=*}"
    local value="${line#*=}"
    if [[ "$value" =~ ^\'[^\']*\'$ || "$value" =~ ^\"[^\"]*\"$ ]]; then
      value="${value:1:-1}"
    fi
    export "$key"="$value"
    echo -e "${GREEN}Loaded:${NC} ${YELLOW}$key${NC}"
    count=$((count + 1))
  done < "$env_file"

  echo -e "\n${GREEN}Finished: Loaded $count variables from $env_file.${NC}"
}