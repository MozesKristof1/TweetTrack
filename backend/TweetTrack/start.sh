#!/bin/sh

echo "Waiting for database..."
/app/waith_for_db.sh postgres 5432

if [ $? -ne 0 ]; then
    echo "Database connection failed!"
    exit 1
fi

echo "Database is up!"

echo "Running Alembic migrations..."
#alembic -c src/alembic.ini upgrade head
alembic -c /app/alembic.ini upgrade head

if [ $? -ne 0 ]; then
    echo "Alembic migration failed!"
    exit 1
fi

echo "Alembic finished!"

echo "Starting Uvicorn server..."
uvicorn main:app --host 0.0.0.0 --port 8000