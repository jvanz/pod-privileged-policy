SOURCE_FILES := $(shell test -e src/ && find src -type f)

policy.wasm: $(SOURCE_FILES) Cargo.*
	cargo build --target=wasm32-wasi --release
	cp target/wasm32-wasi/release/*.wasm policy.wasm

annotated-policy.wasm: policy.wasm metadata.yml
	kwctl annotate -m metadata.yml -o annotated-policy.wasm policy.wasm

.PHONY: fmt
fmt:
	cargo fmt --all -- --check

.PHONY: lint
lint:
	cargo clippy -- -D warnings

.PHONY: e2e-tests
e2e-tests: annotated-policy.wasm
	bats e2e.bats

.PHONY: test
test: fmt lint
	cargo test

.PHONY: clean
clean:
	cargo clean
	rm -f policy.wasm annotated-policy.wasm

sbom-tool:
	curl -Lo sbom-tool https://github.com/microsoft/sbom-tool/releases/download/v0.1.13/sbom-tool-linux-x64
	chmod +x sbom-tool

.PHONY: sbom
sbom: sbom-tool
	./sbom-tool generate \
		-D true \
		-V Verbose \
		-b ./target/wasm32-wasi/release/ \
		-bc . \
		-m . \
		-nsb https://kubewarden.io \
		-nsu kubewarden-policy \
		-pn pod-pribileged-policy \
		-pv test
