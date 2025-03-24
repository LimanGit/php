#!/usr/bin/env bash
DIR="$(cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "$DIR" || { echo "Couldn't change directory to $DIR"; exit 1; }

while getopts "p:f:l" OPTION 2> /dev/null; do
	case ${OPTION} in
		p)
			PHP_BINARY="$OPTARG"
			;;
		f)
			POCKETMINE_FILE="$OPTARG"
			;;
		l)
			DO_LOOP="yes"
			;;
		\?)
			break
			;;
	esac
done

# Custom path to your compiled PHP
if [ -z "$PHP_BINARY" ]; then
	if [ -f /home/container/php/bin/php ]; then
		PHP_BINARY="/home/container/php/php"
	else
		echo "Couldn't find PHP binary in /home/container/php/php"
		exit 1
	fi
fi

# PocketMine file detection
if [ -z "$POCKETMINE_FILE" ]; then
	if [ -f ./PocketMine-MP.phar ]; then
		POCKETMINE_FILE="./PocketMine-MP.phar"
	else
		echo "PocketMine-MP.phar not found"
		echo "Download it from https://github.com/pmmp/PocketMine-MP/releases"
		exit 1
	fi
fi

LOOPS=0

handle_exit_code() {
	local exitcode=$1
	if [ "$exitcode" -eq 134 ] || [ "$exitcode" -eq 139 ]; then
		echo ""
		echo "ERROR: The server crashed with code $exitcode! This might be a PHP issue."
		echo "Consider updating your PHP binary."
		echo ""
	elif [ "$exitcode" -eq 143 ]; then
		echo ""
		echo "WARNING: Server was forcibly killed! This might be due to running out of RAM."
		echo ""
	elif [ "$exitcode" -ne 0 ] && [ "$exitcode" -ne 137 ]; then
		echo ""
		echo "WARNING: Server did not shut down correctly! (code $exitcode)"
		echo ""
	fi
}

set +e

if [ "$DO_LOOP" == "yes" ]; then
	while true; do
		if [ ${LOOPS} -gt 0 ]; then
			echo "Restarted $LOOPS times"
		fi
		"$PHP_BINARY" "$POCKETMINE_FILE" "$@"
		handle_exit_code $?
		echo "To stop the loop, press CTRL+C. Otherwise, the server will restart in 5 seconds."
		sleep 5
		((LOOPS++))
	done
else
	"$PHP_BINARY" "$POCKETMINE_FILE" "$@"
	exitcode=$?
	handle_exit_code $exitcode
	exit $exitcode
fi
