FROM python:3.11-slim-bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libffi-dev libssl-dev zlib1g-dev binutils \
    && pip install --upgrade pip \
    && pip install flask pymongo paramiko pyinstaller

WORKDIR /app

COPY server.py logs_manager.py ./
COPY templates ./templates

RUN pyinstaller --onefile server.py --add-data "templates:templates"

RUN apt-get remove -y gcc libffi-dev libssl-dev zlib1g-dev binutils \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM gcr.io/distroless/base-debian12

WORKDIR /app

COPY --from=builder /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=builder /app/dist/server . 
EXPOSE 5000 

ENTRYPOINT ["/app/server"]
