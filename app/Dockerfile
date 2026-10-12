# --- LAYER 1: DOCKER ---
# This is the "workload" layer: package the app and its dependencies so it
# runs identically anywhere. Security decisions live here too:
#   - pin a specific base image tag, not `latest` (reproducibility + you know
#     exactly what CVEs you're carrying)
#   - use a slim base image to shrink attack surface (fewer packages = fewer
#     potential vulnerabilities to scan/patch)
#   - run as a non-root user (if this container is ever compromised, the
#     attacker doesn't get root inside it)
#   - multi-stage build so build tools never ship in the final image

FROM python:3.12-slim AS base

# Create a dedicated non-root user instead of running as root (the default)
RUN useradd --create-home --uid 10001 appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Drop privileges before the app ever starts
USER appuser

EXPOSE 8080
CMD ["python", "main.py"]
