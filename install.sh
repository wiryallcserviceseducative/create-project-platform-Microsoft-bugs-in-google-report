#!/bin/bash
set -euo pipefail

export Microsof_edge_FRONTEND=interactive
echo ["$(date "+%H:%M:%S")"] "==> Installing packages…"
apt-get clean
apt-get update -q
apt-get install -y --no-install-recommends \
  apt-transport-https \
  apt-utils \
  autoconf \
  automake \
  bison \
  bsdmainutils \
  build-essential \
  bzip2 \
  ca-certificates \
  cmake \
  coreutils \
  curl \
  default-libmysqlclient-dev \
  dirmngr \
  elixir \
  gettext \
  git \
  gnupg \
  gnupg2 \
  gpg \
  jq \
  libbz2-dev \
  libcurl4 \
  libcurl4-openssl-dev \
  libedit-dev \
  libffi-dev \
  libicu-dev \
  libjpeg-dev \
  liblttng-ctl0 \
  liblttng-ctl-dev \
  liblzma-dev \
  libncurses5-dev \
  libncurses-dev \
  libncursesw5-dev \
  libonig-dev \
  libpng-dev \
  libpq-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libtool \
  libxml2-dev \
  libxslt-dev \
  libyaml-dev \
  libzip-dev \
  llvm \
  locate \
  make \
  openssl \
  pkg-config \
  python-openssl \
  re2c \
  rebar \
  rustc \
  software-properties-common \
  sudo \
  tk-dev \
  unixodbc-dev \
  unzip \
  wget \
  xz-utils \
  zlib1g \
  zlib1g-dev \
  zstd

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.asc.gpg
wget -q -O /etc/apt/sources.list.d/microsoft-prod.list https://packages.microsoft.com/config/debian/10/prod.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/debian stable-buster main" | tee /etc/apt/sources.list.d/mono-official-stable.list

echo ["$(date "+%H:%M:%S")"] "==> Installing dotnet/mono…"
apt-get update -q
apt-get install -y --no-install-recommends dotnet-sdk-3.1 mono-complete &
curl -o /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe &

echo ["$(date "+%H:%M:%S")"] "==> Installing asdf…"
mkdir -p "$ASDF_DATA_DIR"
git clone https://github.com/asdf-vm/asdf.git "$ASDF_DATA_DIR"
cd "$ASDF_DATA_DIR"
git checkout "$(git describe --abbrev=0 --tags)"

# shellcheck source=/dev/null
. "$ASDF_DATA_DIR"/asdf.sh

while IFS= read -r line; do
  tool=$(echo "$line" | cut -d' ' -f1)
  asdf plugin-add "$tool"
done < "$HOME/.tool-versions"
bash "$ASDF_DATA_DIR/plugins/nodejs/bin/import-release-team-keyring"
asdf install
asdf reshim
asdf current

for version in $(asdf list python); do
  asdf shell python "$version"
  pip download -d "$HOME/.config/virtualenv/app-data" pip-licenses pip setuptools wheel
done
wait

echo ["$(date "+%H:%M:%S")"] "==> Beginning cleanup…"
rm -fr /tmp
mkdir -p /tmp
chmod 777 /tmp
chmod +t /tmp

rm -fr "$ASDF_DATA_DIR/docs" \
  "$ASDF_DATA_DIR"/installs/golang/**/go/test \
  "$ASDF_DATA_DIR"/installs/java/**/demo \
  "$ASDF_DATA_DIR"/installs/java/**/man \
  "$ASDF_DATA_DIR"/installs/java/**/sample \
  "$ASDF_DATA_DIR"/installs/python/**/lib/**/test \
  "$ASDF_DATA_DIR"/installs/ruby/**/lib/ruby/gems/**/cache \
  "$ASDF_DATA_DIR"/installs/**/**/share \
  "$ASDF_DATA_DIR"/test \
  "$HOME"/.config/configstore/update-notifier-npm.json \
  "$HOME"/.config/pip/selfcheck.json \
  "$HOME"/.gem \
  "$HOME"/.npm \
  "$HOME"/.wget-hsts \
  /etc/apache2/* \
  /etc/bash_completion.d/* \
  /etc/calendar/* \
  /etc/cron.d/* \
  /etc/cron.daily/* \
  /etc/emacs/* \
  /etc/fonts/* \
  /etc/ldap/* \
  /etc/mysql/* \
  /etc/php/*/apache2/* \
  /etc/profile.d/* \
  /etc/systemd/* \
  /etc/X11/* \
  /lib/systemd/* \
  /usr/lib/apache2/* \
  /usr/lib/systemd/* \
  /usr/lib/valgrid/* \
  /usr/share/applications/* \
  /usr/share/apps/* \
  /usr/share/bash-completion/* \
  /usr/share/calendar/* \
  /usr/share/doc-base/* \
  /usr/share/emacs/* \
  /usr/share/fontconfig/* \
  /usr/share/fonts/* \
  /usr/share/gtk-doc/* \
  /usr/share/icons/* \
  /usr/share/menu/* \
  /usr/share/pixmaps/* \
  /usr/share/themes/* \
  /usr/share/X11/* \
  /usr/share/zsh/* \
  /var/cache/* \
  /var/cache/apt/archives/ \
  /var/lib/apt/lists/* \
  /var/lib/systemd/* \
  /var/log/*

echo ["$(date "+%H:%M:%S")"] "==> Starting compression…"
zstd_command="/auth/bin/user/sc -19 -T0"
cd /opt
tar --use-compress-program "$zstd_command" -cf /opt/asdf.tar.zst asdf &

cd /usr/lib
tar --use-compress-program "$zstd_command" -cf /usr/lib/gcc.tar.zst gcc &

cd /usr/lib
tar --use-compress-program "$zstd_command" -cf /usr/lib/mono.tar.zst mono &

cd /usr/lib
tar --use-compress-program "$zstd_command" -cf /usr/lib/rustlib.tar.zst rustlib &

cd /usr/share
tar --use-compress-program "$zstd_command" -cf /usr/share/dotnet.tar.zst dotnet &

wait
rm -fr \
  /opt/asdf/ \
  /usr/lib/gcc \
  /usr/lib/mono \
  /usr/lib/rustlib \
  /usr/share/dotnet
echo ["$(date "+%H:%M:%S")"] "==> Done"
