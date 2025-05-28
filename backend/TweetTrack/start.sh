#!/bin/sh

echo "Waiting for database..."
/app/waith_for_db.sh postgres 5432

if [ $? -ne 0 ]; then
    echo "Database connection failed!"
    exit 1
fi

echo "Database is up!"

cd /app
python create_tables.py

echo "Starting Uvicorn server..."
cd /app/api
uvicorn main:app --host 0.0.0.0 --port 8000