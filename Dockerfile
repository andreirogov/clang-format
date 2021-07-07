# Pass `--build-arg ALPINE_TAG=latest` for the latest alpine build
ARG ALPINE_TAG
ENV ALPINE_TAG ${ALPINE_TAG:-latest}

# Build clang
FROM alpine:${ALPINE_TAG} as clang-format-build

# Build dependencies
RUN apk update && apk add git build-base ninja cmake python3

# Pass `--build-arg LLVM_TAG=main` for the latest llvm commit
ARG LLVM_TAG
ENV LLVM_TAG ${LLVM_TAG:-main}

# Download and setup
WORKDIR /build
RUN git clone --branch ${LLVM_TAG} --depth 1 https://github.com/llvm/llvm-project.git
WORKDIR /build/llvm-project

# Build
WORKDIR llvm/build
RUN cmake -GNinja .. \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DCMAKE_C_FLAGS="-static-libgcc" -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++"
RUN ninja clang-format

# Install clang only
FROM alpine:${ALPINE_TAG}

COPY --from=clang-format-build /build/llvm-project/llvm/build/bin/clang-format /usr/bin

ENTRYPOINT ["clang-format"]
CMD ["--help"]
