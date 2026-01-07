FROM docker:28.1.1 AS static-docker-source
FROM google/cloud-sdk:522.0.0-alpine
COPY --from=static-docker-source /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/libexec/docker/cli-plugins/docker-buildx

WORKDIR /app

# Install 1Password CLI
RUN echo "https://downloads.1password.com/linux/alpinelinux/stable/" >> /etc/apk/repositories \
    && wget -q https://downloads.1password.com/linux/keys/alpinelinux/support@1password.com-61ddfc31.rsa.pub -P /etc/apk/keys \
    && apk update \
    && apk add --no-cache 1password-cli \
    && op --version

# Install yq
RUN wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && yq --version

# Install jq
RUN apk add --no-cache jq \
    && jq --version

# Copy CD functions script into the container
COPY ./functions.sh .

# Make the script executable
RUN chmod +x functions.sh

CMD [ "bash" ]