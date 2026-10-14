#!/usr/bin/env fish
# Start, stop and inspect the Docker Compose stack from anywhere.
#
#   scripts/stack.fish up        start (builds the django image if needed)
#   scripts/stack.fish down      stop; data volumes are kept
#   scripts/stack.fish restart
#   scripts/stack.fish status    services and health
#   scripts/stack.fish logs [service]
#
# This script never removes volumes (no `down -v`).

set -l root (path resolve (status dirname)/..)
cd $root; or exit 1

function dc
    docker compose --project-directory . \
        -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml $argv
end

switch "$argv[1]"
    case up start on
        test -f .env; or begin
            echo "No .env found. Run: cp .env.example .env  and fill in the values."
            exit 1
        end
        dc up -d --build; or exit 1
        dc ps --format 'table {{.Service}}\t{{.Status}}'
        echo
        echo "API health: http://localhost:8080/api/v1/health/"
    case down stop off
        dc down
    case restart
        dc down; and dc up -d --build
    case status ps
        dc ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
    case logs
        dc logs -f $argv[2..-1]
    case '*'
        echo "Usage: scripts/stack.fish up|down|restart|status|logs [service]"
        exit 1
end
