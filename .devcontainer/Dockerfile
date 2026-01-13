ARG DEBIAN_FRONTEND=noninteractive
FROM mcr.microsoft.com/devcontainers/base:bullseye

# Install Node.js (required for Rails asset pipeline and Tailwind)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install additional tools and Ruby build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential gnupg2 tar git zsh libssl-dev zlib1g-dev libyaml-dev curl libreadline-dev \
    imagemagick libjpeg-dev libpng-dev libtiff-dev libwebp-dev libvips libffi-dev libgdbm-dev libncurses5-dev \
    postgresql-client libpq-dev \
    tzdata \
    tmux \
    vim \
    chromium \
    chromium-driver \
    automake \
    libtool \
    bison \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install rbenv and ruby
USER vscode

ARG RUBY_VERSION="4.0.0"
RUN git clone https://github.com/rbenv/rbenv.git /home/vscode/.rbenv  \
    && echo '[ -f "/home/vscode/.rbenv/bin/rbenv" ] && eval "$(rbenv init - bash)" # rbenv' >> /home/vscode/.zshrc \
    && echo '[ -f "/home/vscode/.rbenv/bin/rbenv" ] && eval "$(rbenv init - bash)" # rbenv' >> /home/vscode/.bashrc \
    && echo 'export PATH="/home/vscode/.rbenv/bin:$PATH"' >> /home/vscode/.zshrc \
    && echo 'export PATH="/home/vscode/.rbenv/bin:$PATH"' >> /home/vscode/.bashrc \
    && mkdir -p /home/vscode/.rbenv/versions \
    && mkdir -p /home/vscode/.rbenv/plugins \
    && git clone https://github.com/rbenv/ruby-build.git /home/vscode/.rbenv/plugins/ruby-build

ENV PATH "/home/vscode/.rbenv/bin/:HOME/.rbenv/shims/:$PATH"

RUN rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION && \
    rbenv versions
