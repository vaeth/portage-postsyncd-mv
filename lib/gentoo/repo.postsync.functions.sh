#!/bin/sh
# This file must be sourced. The above line is only for editors
[ -n "${1-}" ] || exit 0
! $only_main || [ "${1-}" = "${POSTSYNC_MAIN_REPOSITORY:-gentoo}" ] || exit 0

repository_name=$1
sync_uri=$2
repository_path=$3

ebegin() {
	provide_functions
	eerror "$@"
}

eend() {
	provide_functions
	eend "$@"
}

einfo() {
	provide_functions
	einfo "$@"
}

ewarn() {
	provide_functions
	ewarn "$@"
}


eerror() {
	provide_functions
	eerror "$@"
}

die() {
	eerror "$@"
	exit 1
}

check_writable() {
	! test -w "$repository_path" || return 0
	eerror "Directory of $repository_name repository non-writable. Try:"
	die "	chown -R $1: $repository_path"
}

provide_functions() {
	provide_functions=':'
	case $- in
	*u*)
		provide_functions='set -u'
		set +u;;
	esac
	: ${EERROR_QUIET=} ${EINFO_LOG=} ${EINFO_QUIET=}
	[ -n "${PORTAGE_QUIET:++}" ] && EINFO_QUIET=yes
	provide_functions_sh=${POSTSYNC_FUNCTIONS_SH:="${EPREFIX-}"/lib/gentoo/functions.sh}
	. ${provide_functions_sh}
	$provide_functions
provide_functions() {
	:
}
}

restart_as_default() {
	restart_as "${POSTSYNC_USER:-portage}" "$@"
}

restart_as() {
	[ "$1" != root ] || return 0
	[ "`id -u`" -eq 0 ] || {
		check_writable "$1"
		return 0
	}
	case $0 in
	/*)
		restart_as_name=$0;;
	*)
		restart_as_name=/etc/portage/repo.postsync.d/${0##*/};;
	esac
	restart_as=$1
	shift
	if [ -z "${POSTSYNC_SHELL:++}" ]
	then	POSTSYNC_SHELL=`command -v sh 2>/dev/null` && \
			[ -n "${POSTSYNC_SHELL:++}" ] || \
			POSTSYNC_SHELL=${EPREFIX-}/bin/sh
	fi
	exec su -p -s "$POSTSYNC_SHELL" -c 'restart_as_name=$1
shift
. "$restart_as_name" "$@"
' "$restart_as" -- /bin/sh "$restart_as_name" "$@"
	die "Failed to exec $restart_as_name as $restart_as"
}

# Usage: max_days_file $days $file [$no-update]
# returns success if filestamp in $file (in repository_path or local/timestamps
# unless a more complete path is specified) is maximally $days old.
# $days=0 counts as infinity (always success). Non-numerical $days means never
# $file is updated unless argument $no-update is non-empty.
max_days_file() {
	case ${1:-x} in
	*[!0-9]*)
		return 1;;
	esac
	case $2 in
	/*)
		max_days_file=$2;;
	*/*)
		max_days_file=$repository_path/${2#./};;
	*)
		max_days_file=$repository_path/local/timestamps/$2;;
	esac
	max_days_file_dir=${max_days_file%/*}
	ebegin "Updating $max_days_file"
	max_days_file_last=0
	if test -r "$max_days_file"
	then	read max_days_file_last max_days_file_ret <"$max_days_file"
	elif [ -z "${3-}" ] && ! test -d "$max_days_file_dir"
	then	mkdir -p -- "$max_days_file_dir" || {
			eend $? "Failed to create $max_days_file_dir"
			exit
		}
	fi
	case ${max_days_file_last:-x} in
	*[!0-9]*)
		max_days_file_last=0;;
	esac
	max_days_file_ret=1
	max_days_file_curr=`date +%s` || max_days_file_curr=
	case ${max_days_file_curr:-x} in
	*[!0-9]*)
		max_days_file_curr=0
		eerror 'Failed to get currrent date';;
	*)
		# 24 * 60 * 60 = 86400 seconds in one day
		[ $1 -gt 0 ] && [ $(( $1 * 86400 )) -lt \
			"$(( $max_days_file_curr - $max_days_file_last ))" ] \
			|| max_days_file_ret=0;;
	esac
	[ -n "${3:++}" ] || printf "%s %s\n" "$max_days_file_curr" \
		"`LC_ALL=C LC_TIME=C date -R || :`" >"$max_days_file" || {
		eend $? "Failed to write to $max_days_file"
		exit
	}
	return $max_days_file_ret
}

# Usage: git_clone [-g] depth remote local_path [Description]
# depth 0 or non-numerical means that no --depth argument is passed
# With option -g, apply git_gc afterwards.
git_clone() {
	if [ "$1" = '-g' ]
	then	shift
		git_clone_gc=git_gc
	else	git_clone_gc=:
	fi
	[ "$1" != '--' ] || shift
	git_clone_depth=${1-}
	case ${1:-x} in
	*[!0-9]*)
		git_clone_depth=;;
	*)
		[ "$1" -ne 0 ] || git_clone_depth=;;
	esac
	shift
	git_clone_remote=$1
	shift
	case $1 in
	/*)
		git_clone_local=$1;;
	*)
		git_clone_local=$repository_path/$1;;
	esac
	shift
	[ $# -gt 0 ] || ebegin "$1"
	if test -d "$git_clone_local"
	then	git -C "$git_clone_local" pull ${PORTAGE_QUIET:+-q} --ff-only \
			${git_clone_depth:+"--depth=$git_clone_depth"}
	else	git clone ${PORTAGE_QUIET:+-q} \
			${git_clone_depth:+"--depth=$git_clone_depth"} \
			-- "$git_clone_remote" "$git_clone_local"
	fi || {
		eend $? "Try to remove $git_clone_local"
		return
	}
	$git_clone_gc "$git_clone_local"
}

# Usage: git_gc dir [message]
git_gc() (
	git_gc_dir=
	case $1 in
	/*)
		git_gc_dir=$1;;
	*)
		git_gc_dir=$repository_path/$1;;
	esac
	cd -- "$git_gc_dir" >/dev/null || exit 0
	export LC_ALL=C LANG=C
	if [ -n "${2:++}" ]
	then	ebegin "$2"
	else	ebegin "Calling git-gc for $git_gc_dir"
	fi
	eval '{
		git prune && \
		git repack -a -d && \
		git reflog expire --expire=now --all && \
		git gc --prune=all --aggressive && \
		git repack -a -d && \
		git prune
	}' ${PORTAGE_QUIET:+>/dev/null}
	eend $?
)
