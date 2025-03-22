FROM python:3.9

RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the backend/TweetTrack directory contents into the container at /app
COPY api /app/api/
COPY src /app/src/
COPY requirements.txt /app
# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
WORKDIR /app/api

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run api.py when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]