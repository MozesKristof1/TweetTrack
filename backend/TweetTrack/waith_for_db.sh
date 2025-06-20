#!/bin/bash

until pg_isready -h postgres -p 5432 -U postgres; do
  echo "Waiting for database to be ready..."
  sleep 2
done

echo "Database is ready!"
