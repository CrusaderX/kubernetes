FROM alpine:3.7

WORKDIR /app

COPY requirements.txt .

RUN apk add python py-pip --update --no-cache && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT ["python","-u","/app/cert-watcher.py"]