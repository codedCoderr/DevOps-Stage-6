FROM python:3.10-slim-bookworm

WORKDIR /app

# Install pip and essential build tools
RUN apt-get update && apt-get install -y python3-pip build-essential gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]
