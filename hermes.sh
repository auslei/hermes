#!/bin/bash

# Check if the container is running
if [ $(docker compose ps -q hermes) ]; then
    # If no arguments are provided, default to opening a shell
    if [ $# -eq 0 ]; then
        echo "No arguments provided. Entering bash shell..."
        docker compose exec -it hermes /bin/bash
    else
        echo "Executing: uv run hermes $@"
        # Passes all script arguments directly to the uv-managed hermes command
        docker compose exec -it hermes uv run hermes "$@"
    fi
else
    echo "Error: Hermes container is not running."
    echo "Run 'docker compose up -d' first."
fi