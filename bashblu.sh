#!/bin/bash

debug() {
  local debug_key='[script-name]'
  local cyan='\033[0;36m'
  local no_color='\033[0;0m'
  if [ -z "$DEBUG" ]; then
    return 0
  fi
  echo "$debug_key" | grep $DEBUG 2> /dev/null
  if [ "$?" != "0" ]; then
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

download_template() {
  local template_name="$1"
  local output="$2"
  local script_name="$3"

  local base_uri="https://raw.githubusercontent.com/octoblu/unix-dev-tools-bashblu/v$(version)/templates"
  debug "downloading $base_uri/$template_name to $output"
  curl --fail -sSL "$base_uri/$template_name" | replace_in_stream "script-name" "$script_name" > "$output"
}

replace_in_stream() {
  local key="$1"
  local value="$(echo "$2" | sed -e 's/[\/&]/\\&/g')"
  sed -e "s/\[$key\]/$value/"
}

usage(){
  echo 'USAGE: bashblu <script-name>'
  echo ''
  echo 'Arguments:'
  echo '  -o, --output       output path'
  echo '  -h, --help         print this help text'
  echo '  -v, --version      print the version'
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
        ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        if [ -n "$script_name" ]; then
          script_name="${param/\.sh}"
        fi
        ;;
    esac
    shift
  done

  if [ -z "$output" ]; then
    output_dir="$PWD/${script_name}.sh"
  fi

  if [ -f "$output" ]; then
    fatal 'script already exists'
  fi

  download_template 'basic-script.sh' "$output" "$script_name" || fatal 'failed to download script template'
  chmod +x "$output" || fatal 'unable to make script exectuable'
}

main "$@"
