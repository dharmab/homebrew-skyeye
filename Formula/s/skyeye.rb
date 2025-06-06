class Skyeye < Formula
  desc "AI Powered GCI Bot for DCS"
  homepage "https://github.com/dharmab/skyeye"
  url "https://github.com/dharmab/skyeye.git", tag: "v1.4.4", revision: "a73d851c76990163594248e83ac38a3769dce24c"
  license "MIT"
  head "https://github.com/dharmab/skyeye.git",
    branch: "main"

  depends_on "go" => :build
  depends_on "pkgconf" => :build
  depends_on "libsoxr"
  depends_on "llvm" # Explicit dependency on Homebrew LLVM due to runtime dependency on OpenMP
  depends_on "opus"

  resource "ggml-small.en.bin" do
    url "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin?download=true"
    sha256 "c6138d6d58ecc8322097e0f987c32f1be8bb0a18532a3f88f734d1bbf9c41e5d"
  end

  def install
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:#{ENV["PATH"]}"
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"
    ENV.deparallelize # libwhisper.a build breaks without this for some reason?
    system "make", "skyeye"

    bin.install "skyeye"
    resource("ggml-small.en.bin").stage do
      (pkgshare/"models").install "ggml-small.en.bin"
    end
    doc.install Dir["docs/*.md"]

    if File.exist?(pkgetc/"config.yaml")
      pkgetc.install "config.yaml" => "config.yaml.default"
    else
      pkgetc.install "config.yaml"
    end
  end

  test do
    system bin/"skyeye", "--help"
    system bin/"skyeye", "--version"
  end

  service do
    run [opt_bin/"skyeye", "--config-file", etc/"skyeye/config.yaml"]
    keep_alive true
    log_path var/"log/skyeye.log"
    error_log_path var/"log/skyeye.log"
    restart_delay 60
  end

  def caveats
    <<~EOS
      A recommended Whisper model is installed at:
        #{HOMEBREW_PREFIX}/share/skyeye/models/ggml-small.en.bin

      You can set the model path in #{pkgetc}/config.yaml:
        whisper-model: #{HOMEBREW_PREFIX}/share/skyeye/models/ggml-small.en.bin
    EOS
  end
end
