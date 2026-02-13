#!/usr/bin/env bash
#
# Run jekyll serve and then launch the site

set -eu

REQUIRED_RUBY="3.1.0"
REQUIRED_BUNDLER="2.4.0"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"

prod=false
command="bundle exec jekyll s -l"
host="127.0.0.1"

version_ge() {
  local current="$1"
  local required="$2"
  ruby -e 'exit(Gem::Version.new(ARGV[0]) >= Gem::Version.new(ARGV[1]) ? 0 : 1)' "$current" "$required"
}

ensure_runtime() {
  local ruby_ver bundle_ver

  if ! command -v ruby >/dev/null 2>&1; then
    echo "Ruby is not installed."
    exit 1
  fi

  ruby_ver="$(ruby -e 'print RUBY_VERSION')"
  if ! version_ge "$ruby_ver" "$REQUIRED_RUBY"; then
    echo "Ruby $ruby_ver detected, but this project requires Ruby >= $REQUIRED_RUBY."
    echo "Try using Ruby 3.1+ (e.g. rbenv/asdf) or run in Docker/Dev Container."
    exit 1
  fi

  if ! command -v bundle >/dev/null 2>&1; then
    echo "Bundler is not installed."
    exit 1
  fi

  bundle_ver="$(bundle --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
  if [[ -z "$bundle_ver" ]]; then
    echo "Could not determine Bundler version."
    exit 1
  fi

  if ! version_ge "$bundle_ver" "$REQUIRED_BUNDLER"; then
    echo "Bundler $bundle_ver detected, but this project expects Bundler >= $REQUIRED_BUNDLER."
    echo "Upgrade Bundler and run: bundle install"
    exit 1
  fi

  if ! bundle check >/dev/null 2>&1; then
    echo "Gem dependencies are missing. Run: bundle install"
    exit 1
  fi
}

help() {
  echo "Usage:"
  echo
  echo "   bash /path/to/run [options]"
  echo
  echo "Options:"
  echo "     -H, --host [HOST]    Host to bind to."
  echo "     -p, --production     Run Jekyll in 'production' mode."
  echo "     -h, --help           Print this help information."
  echo
  echo "Tip:"
  echo "  - Run 'bash tools/doctor.sh' to diagnose local setup issues."
  echo "  - Run 'bash tools/run-docker.sh' to serve using Docker."
}

while (($#)); do
  opt="$1"
  case $opt in
  -H | --host)
    host="$2"
    shift 2
    ;;
  -p | --production)
    prod=true
    shift
    ;;
  -h | --help)
    help
    exit 0
    ;;
  *)
    echo -e "> Unknown option: '$opt'\n"
    help
    exit 1
    ;;
  esac
done

command="$command -H $host"

if $prod; then
  command="JEKYLL_ENV=production $command"
fi

if [ -e /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
  command="$command --force_polling"
fi

ensure_runtime

echo -e "\n> $command\n"
eval "$command"
