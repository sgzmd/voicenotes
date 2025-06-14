#!/bin/bash

set -euo pipefail
set -x

MODEL_DIR="Tests/TranscriptionService/TestModels/tiny"
TMP_DIR=".tmp_whisperkit_clone"
REPO_URL="https://huggingface.co/argmaxinc/whisperkit-coreml"
MODEL_SUBDIR="openai_whisper-tiny.en"

echo "📦 Creating temp clone directory..."
rm -rf "$TMP_DIR"
GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 "$REPO_URL" "$TMP_DIR"

echo "📥 Pulling LFS files for $MODEL_SUBDIR only..."
cd "$TMP_DIR"
git lfs pull --include="$MODEL_SUBDIR/*"

echo "📁 Preparing destination: $MODEL_DIR"
cd ..
rm -rf "$MODEL_DIR"
mkdir -p "$MODEL_DIR"

echo "🚚 Copying model files..."
cp -R "$TMP_DIR/$MODEL_SUBDIR/"* "$MODEL_DIR"

echo "🧹 Cleaning up..."
rm -rf "$TMP_DIR"

echo "✅ Model successfully downloaded to $MODEL_DIR"