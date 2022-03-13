class NetSnmp < Formula
  desc "Custom Net-SNMP build for Easysnmp testing/development on MacOS"
  homepage "http://www.net-snmp.org/"
  url "https://downloads.sourceforge.net/project/net-snmp/net-snmp/5.9.1/net-snmp-5.9.1.tar.gz"
  sha256 "eb7fd4a44de6cddbffd9a92a85ad1309e5c1054fb9d5a7dd93079c8953f48c3f"
  license "Net-SNMP"
  head "https://github.com/net-snmp/net-snmp.git", branch: "master"

  livecheck do
    url :stable
    regex(%r{url=.*?/net-snmp[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    root_url "https://github.com/easysnmp/homebrew-netsnmp-easysnmp/releases/download/net-snmp-5.9.1"
    sha256 big_sur:  "60f0872022fcadfa05fb68be02888f1431142ba2442a793e5a0fb1063ab3e9da"
    sha256 catalina: "91367ab85cf995a1eb5be517d48961b5a1e33f0eec4bdc7f45f0ddc508ae92bf"
  end

  keg_only "macOS provides Net-SNMP 5.6.1 which will break by linking"

  if Hardware::CPU.arm?
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "openssl@1.1"

  # Fix -flat_namespace being used on x86_64 Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    # Workaround https://github.com/net-snmp/net-snmp/issues/226 in 5.9:
    inreplace "agent/mibgroup/mibII/icmp.h", "darwin10", "darwin"

    ENV["CFLAGS"] = "-g -O0"
    ENV["LDFLAGS"] = "-g"

    args = [
      "--disable-debugging",
      "--prefix=#{prefix}",
      "--enable-ipv6",
      "--with-defaults",
      "--with-persistent-directory=#{var}/db/net-snmp",
      "--with-logfile=#{var}/log/snmpd.log",
      # Remove diskio. Diskio emits a general error on OID 1.3.6.1.4.1.2021.13.15.1.1.6.1
      "--with-mib-modules=host",
      "--without-rpm",
      "--without-kmem-usage",
      "--disable-embedded-perl",
      "--without-perl-modules",
      "--with-openssl=#{Formula["openssl@1.1"].opt_prefix}",
    ]

    system "autoreconf", "-fvi" if Hardware::CPU.arm?
    system "./configure", *args
    system "make"
    system "make", "install"
  end

  def post_install
    (var/"db/net-snmp").mkpath
    (var/"log").mkpath
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/snmpwalk -V 2>&1")
  end
end
