#!/bin/bash

# Load environment variables from .env file
set -o allexport
source .env
set +o allexport

# Build Jekyll site in container
# docker exec -it $(docker ps -qf "name=devcontainer") bash -c "cd /workspace && bundle exec jekyll build"

# Copy _site folder to remote server
rsync -azP -c -e "sshpass -p ${SSH_PASSWORD} ssh -o StrictHostKeyChecking=no" _site/* ${SSH_USERNAME}@${REMOTE_URL}:${REMOTE_PATH}


