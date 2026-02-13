#!/usr/bin/env bash
#
# Diagnose common local setup issues for running this site.

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

REQUIRED_RUBY="3.1.0"
REQUIRED_BUNDLER="2.4.0"

pass_count=0
warn_count=0
fail_count=0

ok() {
  pass_count=$((pass_count + 1))
  echo "[OK] $1"
}

warn() {
  warn_count=$((warn_count + 1))
  echo "[WARN] $1"
}

fail() {
  fail_count=$((fail_count + 1))
  echo "[FAIL] $1"
}

version_ge() {
  local current="$1"
  local required="$2"
  ruby -e 'exit(Gem::Version.new(ARGV[0]) >= Gem::Version.new(ARGV[1]) ? 0 : 1)' "$current" "$required"
}

check_ruby() {
  if ! command -v ruby >/dev/null 2>&1; then
    fail "Ruby is not installed."
    return
  fi

  local ruby_ver
  ruby_ver="$(ruby -e 'print RUBY_VERSION')"

  if version_ge "$ruby_ver" "$REQUIRED_RUBY"; then
    ok "Ruby version is $ruby_ver (required >= $REQUIRED_RUBY)."
  else
    fail "Ruby version is $ruby_ver. This project requires Ruby >= $REQUIRED_RUBY."
  fi
}

check_bundler() {
  if ! command -v bundle >/dev/null 2>&1; then
    fail "Bundler is not installed."
    return
  fi

  local bundle_ver
  bundle_ver="$(bundle --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"

  if [[ -z "$bundle_ver" ]]; then
    fail "Could not determine Bundler version."
    return
  fi

  if version_ge "$bundle_ver" "$REQUIRED_BUNDLER"; then
    ok "Bundler version is $bundle_ver (required >= $REQUIRED_BUNDLER)."
  else
    fail "Bundler version is $bundle_ver. Please use Bundler >= $REQUIRED_BUNDLER."
  fi
}

check_bundle_deps() {
  if bundle check >/dev/null 2>&1; then
    ok "Gem dependencies are installed."
  else
    warn "Gem dependencies are missing. Run: bundle install"
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker is not installed. Docker-based run is unavailable."
    return
  fi

  if docker info >/dev/null 2>&1; then
    ok "Docker daemon is running."
  else
    warn "Docker is installed but daemon is not running."
  fi
}

check_post_front_matter() {
  local output
  if ! output="$(ruby <<'RUBY'
require "date"
require "yaml"

errors = []
Dir.glob("_posts/*.{md,markdown,html}").sort.each do |path|
  content = File.read(path, encoding: "UTF-8")

  unless content.start_with?("---\n")
    errors << "#{path}: missing opening front matter delimiter"
    next
  end

  delimiter_index = content.index("\n---\n", 4)
  if delimiter_index.nil?
    errors << "#{path}: missing closing front matter delimiter"
    next
  end

  front_matter = content[4...delimiter_index]

  begin
    data = YAML.safe_load(front_matter, permitted_classes: [Date, Time], aliases: true) || {}
  rescue StandardError => e
    errors << "#{path}: invalid front matter YAML (#{e.message})"
    next
  end

  errors << "#{path}: missing 'title' in front matter" if data["title"].to_s.strip.empty?
  errors << "#{path}: missing 'date' in front matter" if data["date"].to_s.strip.empty?
end

puts errors.join("\n")
exit(errors.empty? ? 0 : 1)
RUBY
)"; then
    fail "Post front matter issues found:"
    echo "$output"
    return
  fi

  ok "Post front matter check passed."
}

main() {
  echo "Running site diagnostics in: $ROOT_DIR"
  echo

  check_ruby
  check_bundler
  check_bundle_deps
  check_docker
  check_post_front_matter

  echo
  echo "Summary: ${pass_count} passed, ${warn_count} warnings, ${fail_count} failed"

  if ((fail_count > 0)); then
    exit 1
  fi
}

main "$@"
