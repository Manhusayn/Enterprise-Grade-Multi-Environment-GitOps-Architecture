FROM python:3.12-alpine

RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY src/ /app/src/

USER app
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

EXPOSE 8080

CMD ["python", "/app/src/app.py"]
