FROM myoung34/github-runner:latest

ARG KUBECTL_VERSION=v1.30.4
ARG HELM_VERSION=v3.15.4
ARG KUSTOMIZE_VERSION=v5.4.3

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      tar \
      gzip \
    && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# helm
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz \
    && tar -xzf /tmp/helm.tar.gz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# kustomize
RUN curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" -o /tmp/kustomize.tar.gz \
    && tar -xzf /tmp/kustomize.tar.gz -C /usr/local/bin \
    && rm -f /tmp/kustomize.tar.gz

# yq
RUN curl -fsSLo /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq
