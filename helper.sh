#!/bin/sh
set -eu

# Current directory
DIR=$(dirname $0)
cd $DIR

# Must match lib/env.sh
MIRROR=https://bintray.com/dfabric/apps-static/download_file?file_path=

DIR=$PWD
KERNEL=$(uname -s | tr A-Z a-z)

APP=${APP-${1-}}

case $(uname -m) in
	x86_64) ARCH=x86-64;;
	i*86) ARCH=x86;;
	aarch64) ARCH=arm64;;
	armv7*) ARCH=armhf;;
	*) printf "Error: $(uname -m) - unsupported architecture\n"; usage 1;;
esac
ARCH=${3-$ARCH}

SYSTEM=${KERNEL}_$ARCH

# Network functions
if hash curl 2>/dev/null ;then
	download() { [ "${2-}" ] && curl -\#L "$1" -o "$2"; }
	getstring() { curl -Ls $@; }
elif hash wget 2>/dev/null ;then
	download() { [ "${2-}" ] && wget "$1" -O "$2"; }
	getstring() { wget -qO- $@; }
else
	error 'curl or wget not found' 'you need to install either one of them'
fi

usage() {
	cat <<EOF
usage: $0 [package] {version} {architecture}
The package will be downloaded in \`$DIR\` 

Available packages for $SYSTEM:
$(getstring $MIRROR/SHA512SUMS | sed -n "s/.*  \(.*\)_$SYSTEM.*/\1\]/p" | tr _ \[)

Available architectures:
[x86-64, x86, armhf, arm64] (default: $ARCH)

EOF
	exit $1
}

case $APP in
	-h|--help|'') usage 0;
esac

# Current shell used by the user
SH=$0
SH=${SH##*\/}

sha512sums=$(getstring $MIRROR/SHA512SUMS)
package=$(printf "$sha512sums\n" | grep -o "${APP}_${2-.*}_$SYSTEM.tar.xz" || true)

if ! [ "$package" ] ;then
	echo "$1 package not found in $MIRROR"
	usage 1
else
	name=${package%.tar.xz}

	# Very shasum
	shasum=$(printf "$sha512sums\n "| grep "$package")
	download $MIRROR/$package $package
	case $shasum in
		"$(sha512sum $package)") echo "SHA512SUMS match for $package";;
		*) echo "SHA512SUMS" "don't match for $package"; exit 1;;
	esac
	echo "Extracting..."
	tar xJf $package
	rm $package
	echo "downloaded: \`$DIR/$name\`"
fi
