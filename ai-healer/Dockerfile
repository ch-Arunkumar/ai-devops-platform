FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ .
RUN python -c "import flask; import openai; import kubernetes; print('All imports OK')"
EXPOSE 5010
CMD ["gunicorn", "--workers", "1", "--bind", "0.0.0.0:5010", "--timeout", "120", "healer:app"]