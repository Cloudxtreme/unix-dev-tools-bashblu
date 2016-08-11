#!/bin/bash

DEBUG_KEY='bashblu'

download_template() {
  local template_name="$1"
  local output_dir="$2"
  local script_name="$3"

  local base_uri="https://raw.githubusercontent.com/octoblu/unix-dev-tools-bashblu/$(version)/templates/"
  debug "downloading $template_name to $output_dir"
  curl -sSL "$base_uri/$template_name" | replace_in_stream "script-name" "$script_name" > "$output_dir/${script_name}.sh"
}

replace_in_stream() {
  local key="$1"
  local value="$(echo "$2" | sed -e 's/[\/&]/\\&/g')"
  sed -e "s/\[$key\]/$value/"
}

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
  echo 'USAGE: bashblu <script-name>'
  echo ''
  echo 'Arguments:'
  echo '  -o, --output       output folder path. Defaults to cwd'
  echo '  -p, --project      generate standalone project files'
  echo '  -h, --help         print this help text'
  echo '  -v, --version      print the version'
}

version(){
  local directory="$(script_directory)"
  local version=$(cat "$directory/VERSION")

  echo "$version"
}

main() {
  local project="false"
  local output_dir=""

  local script_name="$1";
  while [ "$1" != "" ]; do
    local param=`echo $1 | awk -F= '{print $1}'`
    local value=`echo $1 | awk -F= '{print $2}'`
    case $param in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      -p | --project)
        project="true"
        ;;
      -c | --create)
        output_dir="$value"
        ;;
      *)
        if [ -z "$script_name" ]; then
          echo "ERROR: unknown parameter \"$param\""
          usage
          exit 1
        fi
        script_name="${param/\.sh}"
        ;;
    esac
    shift
  done

  if [ -z "$output_dir" ]; then
    output_dir="$PWD"
  fi 

  if [ "$project" == "true" ]; then
    download_template 'project-script.sh' "$output_dir" "${script_name}" || fatal 'failed to download script template' 
    chmod +x "$output_dir/${script_name}.sh" || fatal 'unable to make script exectuable'
    if [ ! -f "$VERSION" ]; then
      echo '1.0.0' > "$output_dir/VERSION"
    fi
  else
    download_template 'standalone-script.sh' "$output_dir" "${script_name}" || fatal 'failed to download script template' 
    chmod +x "$output_dir/${script_name}.sh" || fatal 'unable to make script exectuable'
  fi
}

main "$@"
