FROM debian:bookworm-slim AS module-builder

ENV NGINX_VERSION=1.29.1

WORKDIR /usr/src

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       libpcre3-dev \
       zlib1g-dev \
       libssl-dev \
       libclang-dev \
       git \
       wget \
       openssl \
       libssl-dev \
       pkg-config \
       ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://sh.rustup.rs | RUSTUP_HOME=/opt/rust CARGO_HOME=/opt/rust sh -s -- --no-modify-path -y \
    && echo 'export RUSTUP_HOME=/opt/rust' | tee -a /etc/profile.d/rust.sh \
    && echo 'export PATH=$PATH:/opt/rust/bin' | tee -a /etc/profile.d/rust.sh

RUN wget -qO- https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar zxvf -

RUN git clone --depth 1 https://github.com/nginx/nginx-acme.git


RUN cd nginx-$NGINX_VERSION \
    && export PATH=$PATH:/opt/rust/bin \
    && export RUSTUP_HOME=/opt/rust \
    && ./configure --with-compat  --with-http_ssl_module --add-dynamic-module=../nginx-acme \
    && make modules

FROM nginx:1.29.1-bookworm

RUN mkdir -p /etc/nginx/modules/

COPY --from=module-builder /usr/src/nginx-$NGINX_VERSION/objs/ngx_http_acme_module.so /etc/nginx/modules/ngx_http_acme_module.so