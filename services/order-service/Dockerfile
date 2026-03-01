FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ .
EXPOSE 5002
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5002", "app:app"]
