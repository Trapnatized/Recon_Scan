# # Multi-stage build for Go tools
FROM golang:alpine AS builder

ENV GO111MODULE=on \
    CGO_ENABLED=0
RUN go install -v github.com/tomnomnom/anew@latest && \
    go install -v github.com/tomnomnom/assetfinder@latest && \
    go install github.com/tomnomnom/httprobe@latest && \
    go install -v github.com/haccer/subjack@latest && \
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install -v github.com/projectdiscovery/uncover/cmd/uncover@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 

# Final stage
FROM alpine:latest

# Install basic requirements
RUN apk update && apk add --no-cache \
    bash \
    git \
    curl \
    wget \
    python3 \
    py3-pip \
    jq \
    nmap \
    figlet 

# Set up Go environment in final stage
ENV GOPATH=/go
ENV PATH=$PATH:/go/bin

# Copy Go package and binaries from builder
COPY --from=builder /go/pkg/mod/github.com/haccer/subjack@v0.0.0-20201112041112-49c51e57deab/* /go/pkg/mod/github.com/haccer/subjack@v0.0.0-20201112041112-49c51e57deab/
COPY --from=builder /go/bin/* /usr/local/bin/

# Create directories and setup tools
RUN mkdir -p /opt/tools

# Clone and setup tools
RUN git clone https://github.com/iamj0ker/bypass-403 /opt/tools/bypass-403 && \
    chmod +x /opt/tools/bypass-403/bypass-403.sh

# Copy your recon script
COPY recon.sh /opt/tools/
RUN chmod +x /opt/tools/recon.sh

# Copy config files
RUN mkdir -p /root/.config/uncover /root/.config/subfinder
COPY  configs/uncover/* /root/.config/uncover/
COPY configs/subfinder/* /root/.config/subfinder/

# Create working directory
WORKDIR /data

ENTRYPOINT ["/opt/tools/recon.sh"]
