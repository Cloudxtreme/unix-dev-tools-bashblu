#!/bin/bash

DEBUG_KEY='[script-name]'

debug() {
  if [ -z "$DEBUG" ]; then
    return 0
  fi
  local message="$1"
  echo "$DEBUG_KEY: $message"
}

fatal() {
  local message="$1"
  echo "Error: $message"
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
  echo 'USAGE: [script-name].sh <some-arg>'
  echo ''
  echo 'Arguments:'
  echo '  -a, --arg          an example arg'
  echo '  -s, --say          an example arg with a value'
  echo '  -h, --help         print this help text'
  echo '  -v, --version      print the version'
}

version(){
  echo "1.0.0"
}

main() {
  local arg="false"
  local say=""

  local some_arg="$1";
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
      -a | --arg)
        arg="true"
        ;;
      -s | --say)
        say="$value"
        shift
        ;;
      *)
        if [ "${param::1}" == '-' ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        if [ -z "$param" ]; then
          some_arg="$param"
        fi
        ;;
    esac
    shift
  done

  echo "some_arg: $some_arg"
  echo "say: $say"
  echo "arg: $arg"
}

main "$@"
