class Skyeye < Formula
  desc "AI Powered GCI Bot for DCS"
  homepage "https://github.com/dharmab/skyeye"
  url "https://github.com/dharmab/skyeye.git", tag: "v1.4.0", revision: "80751eaf96fad8f63f598b174f8311f2bf6d87e0"
  license "MIT"
  head "https://github.com/dharmab/skyeye.git",
    branch: "main"

  depends_on "go" => :build
  depends_on "pkgconf" => :build
  depends_on "libsoxr"
  depends_on "llvm" # Explicit depdenency on Homebrew LLVM due to runtime dependency on OpenMP
  depends_on "opus"

  def install
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:#{ENV["PATH"]}"
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"
    ENV.deparallelize # libwhisper.a build breaks without this for some reason?
    system "make", "skyeye"
    bin.install "skyeye"
    doc.install Dir["docs/*.md"]
    if File.exist?(etc/"skyeye/config.yaml")
      (etc/"skyeye").install "config.yaml" => "config.yaml.default"
    else
      (etc/"skyeye").install "config.yaml"
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
end
