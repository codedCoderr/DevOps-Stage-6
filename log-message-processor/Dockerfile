# log-processor/Dockerfile
# Use a full Python image to ensure all necessary build dependencies are available
FROM python:3.11

WORKDIR /app

# Install dependencies first
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Adjust if your main script is named differently, but typically it's main.py
CMD ["python", "main.py"]