FROM python:3.9

RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get install -y ffmpeg postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the backend/TweetTrack directory contents into the container at /app
COPY api /app/api/
COPY src /app/src/
COPY start.sh /app/start.sh
COPY requirements.txt /app
COPY waith_for_db.sh /app
COPY /src/create_tables.py /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
RUN chmod +x /app/start.sh
RUN chmod +x /app/waith_for_db.sh
WORKDIR /app/api

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run api.py when the container launches
CMD ["sh", "/app/start.sh"]