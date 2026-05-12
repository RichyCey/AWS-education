#!/bin/bash
set -e

ollama serve &

until curl -sf http://localhost:11434/ > /dev/null 2>&1; do
  sleep 1
done

ollama pull tinyllama

wait
