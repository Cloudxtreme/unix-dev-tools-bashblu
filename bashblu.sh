#!/bin/bash

SCRIPT_NAME='bashblu'

matches_debug() {
  if [ -z "$DEBUG" ]; then
    return 1
  fi
  if [[ $SCRIPT_NAME == $DEBUG ]]; then
    return 0
  fi
  return 1
}

debug() {
  local cyan='\033[0;36m'
  local no_color='\033[0;0m'
  local message="$@"
  matches_debug || return 0
  (>&2 echo -e "[${cyan}${SCRIPT_NAME}${no_color}]: $message")
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

assert_required_params() {
  local output="$1"

  if [ -f "$output" ]; then
    fatal 'script already exists'
  fi

  if [ -n "$output" ]; then
    return 0
  fi

  usage

  if [ -z "$output" ]; then
    echo "Missing output argument"
  fi

  exit 1
}

download_template() {
  local template_name="$1"
  local output="$2"
  local script_name="$3"

  local base_uri="https://raw.githubusercontent.com/octoblu/unix-dev-tools-bashblu/v$(version)/templates"
  debug "downloading $base_uri/$template_name to $output"
  debug "replacing [script-name] with '$script_name'"
  curl --fail -sSL "$base_uri/$template_name" | replace_in_stream "script-name" "$script_name" > "$output"
}

replace_in_stream() {
  local key="$1"
  local value="$(echo "$2" | sed -e 's/[\/&]/\\&/g')"
  sed -e "s/\[$key\]/$value/"
}

usage(){
  echo "USAGE: ${SCRIPT_NAME} <script-name>"
  echo ''
  echo 'Description: generate a bash script'
  echo ''
  echo 'Arguments:'
  echo '  -o, --output       output path'
  echo '  -h, --help         print this help text'
  echo '  -v, --version      print the version'
  echo ''
  echo 'Environment:'
  echo '  DEBUG              print debug output'
  echo ''
}

version(){
  local directory="$(script_directory)"

  if [ -f "$directory/VERSION" ]; then
    cat "$directory/VERSION"
  else
    echo "unknown-version"
  fi
}

main() {
  local output=""
  local script_name=""

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
      -o | --output)
        output="$value"
        shift
        ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        if [ -z "$script_name" ]; then
          script_name="${param/\.sh}"
        fi
        ;;
    esac
    shift
  done

  if [ -z "$output" ]; then
    output="$PWD/${script_name}.sh"
  fi

  assert_required_params "$output"

  download_template 'basic-script.sh' "$output" "$script_name" || fatal 'failed to download script template'
  chmod +x "$output" || fatal 'unable to make script exectuable'
}

main "$@"
