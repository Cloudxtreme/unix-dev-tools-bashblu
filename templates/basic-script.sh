#!/bin/bash

debug() {
  local debug_key='[script-name]'
  local cyan='\033[0;36m'
  local no_color='\033[0;0m'
  if [ -z "$DEBUG" ]; then
    return 0
  fi
  echo "$debug_key" | grep "$DEBUG"
  local is_valid_debug="$?"
  if [ "$debug_key" == '*' -a "$is_valid_debug" != "0" ]; then
    return 0
  fi
  local message="$@"
  (>&2 echo -e "[${cyan}${debug_key}${no_color}]: $message")
}

fatal() {
  local message="$1"
  (>&2 echo "Error: $message")
  exit 1
}

script_directory(){
  local source="${BASH_SOURCE[0]}"
  local dir=""

  while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done

  dir="$( cd -P "$( dirname "$source" )" && pwd )"

  echo "$dir"
}

usage(){
  echo 'USAGE: [script-name]'
  echo ''
  echo 'Arguments:'
  echo '  -h, --help         print this help text'
  echo '  -v, --version      print the version'
  echo 'Environment:'
  echo '  DEBUG              print debug output'
}

version(){
  local directory="$(script_directory)"

  if [ -f "$directory/VERSION" ]; then
    cat "$directory/VERSION"
  else
    echo "unknown"
  fi
}

main() {
  while [ "$1" != "" ]; do
    local param="$1"
    local value="$2"
    case "$param" in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        ;;
    esac
    shift
  done
}

main "$@"
