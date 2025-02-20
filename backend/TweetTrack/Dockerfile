FROM python:3.9

# Copy the backend/TweetTrack directory contents into the container at /app
COPY /api /app/
COPY /src /app/

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
WORKDIR /app/api

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run api.py when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]