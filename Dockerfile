ARG RESTIC_VERSION
ARG RCLONE_VERSION
ARG DENO_VERSION

ARG RESTIC_TAG=${RESTIC_VERSION:+${RESTIC_VERSION}}
ARG RESTIC_TAG=${RESTIC_TAG:-latest}
ARG RCLONE_TAG=${RCLONE_VERSION:+${RCLONE_VERSION}}
ARG RCLONE_TAG=${RCLONE_TAG:-latest}
ARG DENO_TAG=${DENO_VERSION:+alpine-${DENO_VERSION}}
ARG DENO_TAG=${DENO_TAG:-alpine}

# Ref: https://github.com/restic/restic/blob/master/docker/Dockerfile.release
FROM restic/restic:${RESTIC_TAG} AS restic

RUN ls -al /usr/bin/restic

# Ref: https://github.com/rclone/rclone/blob/master/contrib/docker-plugin/managed/Dockerfile
FROM rclone/rclone:${RCLONE_TAG} AS rclone

RUN ls -al /usr/local/bin/rclone

# Ref: https://github.com/denoland/deno_docker/blob/main/alpine.dockerfile
FROM denoland/deno:${DENO_TAG} AS deno

RUN ls -al /bin/deno

# Ref: https://github.com/denoland/deno_docker/blob/main/alpine.dockerfile
FROM gcr.io/distroless/cc AS cc

FROM alpine:latest

COPY --from=cc --chown=root:root --chmod=755 /lib/*-linux-gnu/* /usr/local/lib/
COPY --from=cc --chown=root:root --chmod=755 /lib/ld-linux-* /lib/

RUN mkdir /lib64 \
    && ln -s /usr/local/lib/ld-linux-* /lib64/

ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV DENO_USE_CGROUPS=1

COPY --from=restic --chown=root:root --chmod=755 /usr/bin/restic /usr/local/bin/restic
COPY --from=rclone --chown=root:root --chmod=755 /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=deno --chown=root:root --chmod=755 /bin/deno /usr/local/bin/deno

RUN apk add --no-cache ca-certificates fuse openssh-client tzdata jq \
    && apk --no-cache add ca-certificates fuse3 tzdata \
    && apk add --no-cache bash \
    && ls -al /usr/local/bin \
    && restic version \
    && rclone version \
    && deno --version

CMD ["bash"]