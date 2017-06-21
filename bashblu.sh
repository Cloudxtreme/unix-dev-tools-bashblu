#!/bin/bash

SCRIPT_NAME='bashblu'

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

matches_debug() {
  if [ -z "$DEBUG" ]; then
    return 1
  fi
  # shellcheck disable=SC2053
  if [[ $SCRIPT_NAME == $DEBUG ]]; then
    return 0
  fi
  return 1
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
  local output_filename script_name
  output_filename="$1"
  script_name="$2"

  if [ -f "$output_filename" ]; then
    fatal "'$output_filename' script already exists"
  fi

  if [ -n "$output_filename" ] && [ -n "$script_name" ]; then
    return 0
  fi

  usage

  if [ -z "$script_name" ]; then
    echo "Missing <script-name> argument"
  fi

  exit 1
}

get_template() {
  # HOMEBREW HOOK: get_template

  cat "$(script_directory)/templates/basic-script.sh"
}

process_template() {
  local template script_name
  template="$1"
  script_name="$2"

  echo "$template" | replace_in_stream "script-name" "$script_name"
}

replace_in_stream() {
  local key value
  key="$1"
  value="$(echo "$2" | sed -e 's/[\/&]/\\&/g')"
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
  # HOMEBREW HOOK: version
  local directory
  directory="$(script_directory)"

  if [ -f "$directory/VERSION" ]; then
    cat "$directory/VERSION"
  else
    echo "unknown-version"
  fi
}

main() {
  local output_filename
  local script_name

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
        output_filename="$value"
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

  if [ -z "$output_filename" ] && [ -n "$script_name" ]; then
    output_filename="$PWD/${script_name}.sh"
  fi

  assert_required_params "$output_filename" "$script_name"


  template="$(get_template)"                                    || fatal "failed to get template"
  file_content="$(process_template "$template" "$script_name")" || fatal "failed to process template"
  echo "$file_content" > "$output_filename"                     || fatal "failed to write to '$output_filename'"
  chmod +x "$output_filename"                                   || fatal 'unable to make script exectuable'
}

main "$@"
