# Dev Container - Nix-based portable development environment
#
# Build:  docker build -t dev-container .
# Run:    docker-compose up -d && docker-compose exec dev zsh
FROM nixos/nix:latest AS builder

# Enable flakes and other experimental features
RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "filter-syscalls = false" >> /etc/nix/nix.conf

WORKDIR /build

# Copy dependency files first for better layer caching
COPY flake.nix flake.lock* shell.nix ./
COPY config/ ./config/

# Build the nix development profile (installs all packages from shell.nix)
RUN nix develop --profile /nix/dev-profile --command true 2>/dev/null || \
    nix-shell shell.nix --run true

# --- Runtime stage ---
FROM nixos/nix:latest

RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "filter-syscalls = false" >> /etc/nix/nix.conf

# Copy the pre-built profile from builder
COPY --from=builder /nix /nix

# Create dev user and home structure
RUN nix-channel --update 2>/dev/null || true && \
    mkdir -p /home/dev/.config/git \
             /home/dev/.config/starship \
             /home/dev/.config/mprocs \
             /home/dev/.local/bin \
             /home/dev/.zsh \
             /home/dev/.cache \
             /workspace

WORKDIR /build

# Copy project files
COPY flake.nix flake.lock* shell.nix ./
COPY config/ ./config/
COPY setup.sh ./setup.sh
RUN chmod +x ./setup.sh

# Set environment
ENV HOME=/home/dev \
    USER=dev \
    TERM=xterm-256color \
    LANG=C.UTF-8

WORKDIR /workspace

EXPOSE 3000 5173 8080 4321

ENTRYPOINT ["/build/setup.sh"]
CMD ["zsh"]
