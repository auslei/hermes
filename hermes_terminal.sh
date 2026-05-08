#!/bin/bash

if [ $(docker compose ps -q hermes) ]; then
    echo "Entering Hermes Shell..."
    # 1. Enter the bash shell of the running container
    # 2. Once inside, we call 'gateway' or 'hermes'
    docker compose exec -it hermes /bin/bash
else
    echo "Error: Hermes container is not running."
    echo "Try: docker compose up -d"
fi