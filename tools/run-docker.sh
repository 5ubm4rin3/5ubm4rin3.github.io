#!/usr/bin/env bash
#
# Run Jekyll in Docker to avoid local Ruby/Bundler dependency issues.

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

IMAGE="jekyll/jekyll:4.3"
CONTAINER_PORT=4000
host="127.0.0.1"
port="4000"
prod=false

help() {
  echo "Usage:"
  echo
  echo "   bash /path/to/run-docker [options]"
  echo
  echo "Options:"
  echo "     -H, --host [HOST]    Host to bind to."
  echo "     -P, --port [PORT]    Port to bind to."
  echo "     -p, --production     Run Jekyll in 'production' mode."
  echo "     -h, --help           Print this help information."
}

while (($#)); do
  opt="$1"
  case $opt in
  -H | --host)
    host="$2"
    shift 2
    ;;
  -P | --port)
    port="$2"
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

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running. Start Docker Desktop first."
  exit 1
fi

jekyll_cmd="bundle config set --local path vendor/bundle && bundle install && bundle exec jekyll s -l -H $host -P $CONTAINER_PORT"

if $prod; then
  jekyll_cmd="JEKYLL_ENV=production $jekyll_cmd"
fi

echo -e "\n> docker run --rm -v \"$ROOT_DIR:/srv/jekyll\" -p \"$port:$CONTAINER_PORT\" $IMAGE ...\n"

docker run --rm \
  -v "$ROOT_DIR:/srv/jekyll" \
  -w /srv/jekyll \
  -p "$port:$CONTAINER_PORT" \
  "$IMAGE" \
  bash -lc "$jekyll_cmd"
