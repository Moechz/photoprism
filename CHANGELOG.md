# Changelog

All notable user-visible changes to the PhotoPrism TOS application package.

## 261029-2 — 2026-11-12

### Changed
- Icon: replaced the letter monogram with a functional vector mark that describes what the app does (the upstream project does not publish a compliant SVG).

## 261029-1 — 2026-11-09

### Added
- First release. PhotoPrism (`photoprism/photoprism:261029`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8022 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/photoprismdocker/`.
