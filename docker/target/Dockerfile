FROM alpine:latest

# Install Python, pip, and curl
RUN apk add --no-cache python3 py3-pip curl

# Create a new user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create the /app directory
RUN mkdir -p /app
WORKDIR /app
RUN chown -R appuser:appgroup /app

USER appuser

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# Default command
CMD ["sh"]