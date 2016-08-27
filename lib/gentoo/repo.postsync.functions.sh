#!/bin/sh
# This file must be sourced. The above line is only for editors
[ -n "${1-}" ] || exit 0
: ${POSTSYNC_MAIN_REPOSITORY:=gentoo}
! $only_main || [ x"${1-}" = x"$POSTSYNC_MAIN_REPOSITORY" ] || exit 0

repository_name=$1
sync_uri=$2
repository_path=$3

output_n() {
	[ x"$LAST_E_CMD" != x'ebegin' ] || echo
	printf '%s' "$1$RC_INDENTATION$2"
	LAST_E_CMD=$3
}

output_l() {
	output_n "$1" "$2
" "$3"
}

eindent() {
	RC_INDENTATION=$RC_INDENTATION'  '
}

eoutdent() {
	RC_INDENTATION=${RC_INDENTATION%  }
}

einfo_quiet() {
	if [ -n "${PORTAGE_QUIET:++}" ] || yesno "${EINFO_QUIET-}"
	then
einfo_quiet() {
:
}
	else
einfo_quiet() {
	return 1
}
	fi
	einfo_quiet
}

init_colors() {
	RC_ENDCOL=1
	if [ -z "${CONSOLETYPE:++}" ]
	then	CONSOLETYPE=`consoletype stdout 2>/dev/null`
		export CONSOLETYPE
	fi
	if [ x"$CONSOLETYPE" = x'serial' ]
	then	RC_NOCOLOR=1
		RC_ENDCOL=0
	fi
	if yesno "${RC_NOCOLOR-}"
	then	NORMAL=
		GOOD=
		WARN=
		BAD=
		HILITE=
		BRACKET=
	elif tput color >/dev/null 2>&1
	then	NORMAL=`tput sgr0`
		init_colors=$NORMAL`tput bold`
		GOOD=$init_colors`tput setaf 2`
		WARN=$init_colors`tput setaf 3`
		BAD=$init_colors`tput setaf 1`
		HILITE=$init_colors`tput setaf 6`
		BRACKET=$init_colors`tput setaf 4`
	else	NORMAL=`printf '\033[0m'`
		GOOD=`printf '\033[32;01m'`
		WARN=`printf '\033[33;01m'`
		BAD=`printf '\033[31;01m'`
		HILITE=`printf '\033[36;01m'`
		BRACKET=`printf '\033[34;01m'`
	fi
	RC_INDENTATION=
	LAST_E_CMD=
	init_colors=${COLUMNS:-0}
	[ "$init_colors" -gt 0 ] || {
		init_colors="set -- `stty size 2>/dev/null`"
		init_colors=`$init_colors
printf '%s' "$2"`
		: ${init_colors:=0}
        }
	[ "$init_colors" -ge 6 ] && [ "$init_colors" -le 80 ] || init_colors=80
	init_colors=$(( $init_colors - 6 ))
	if yesno "$RC_ENDCOL"
	then	eval 'rc_end() {
	printf '\''\r\n\033[A\033['"$init_colors"'C%s\n'\'' "$*"
}'
	else	eval 'rc_end() {
	printf '\''\n%'"$init_colors"'s\n'\'' "$*"
}'
	fi
init_colors() {
:
}
}

esyslog() {
	yesno "${EINFO_LOG-}" && command -v logger >/dev/null 2>&1 || exit 0
	esyslog_pri=$1
	esyslog_tag=$2
	shift 2
	[ -n "${*:++}" ] || exit 0
	logger -p "$esyslog_pri" -t "$esyslog_tag" -- "$@*"
}

einfon() {
	! einfo_quiet || return 0
	init_colors
	output_n " ${GOOD}*$NORMAL " "$*" einfon
}

einfo() {
	! einfo_quiet || return 0
	init_colors
	output_l " ${GOOD}*$NORMAL " "$*" einfo
}

ewarnn() {
	! einfo_quiet || return 0
	init_colors
	output_n " ${WARN}*$NORMAL " "$*" ewarnn >&2
	esyslog daemon.warning "${0##*/}" "$*"
}

ewarn() {
	! einfo_quiet || return 0
	init_colors
	output_l " ${WARN}*$NORMAL " "$*" ewarn >&2
	esyslog daemon.warning "${0##*/}" "$*"
}

eerrorn() {
	! yesno "${EERROR_QUIET-}" || return
	init_colors
	output_n " ${BAD}*$NORMAL " "$*" eerrorn >&2
	esyslog daemon.err "${0##*/}" "$*"
	return 1
}

eerror() {
	! yesno "${EERROR_QUIET-}" || return
	init_colors
	output_l " ${BAD}*$NORMAL " "$*" eerror >&2
	esyslog daemon.err "${0##*/}" "$*"
}

ebegin() {
	! einfo_quiet || return 0
	init_colors
	output_n " ${GOOD}*$NORMAL " "${*-} ..." ebegin
}

eend_sub() {
	if [ "$1" -eq 0 ]
	then	! einfo_quiet || return 0
		init_colors
		rc_end "$BRACKET[ ${GOOD}ok$BRACKET ]$NORMAL"
		LAST_E_CMD=$2
		return 0
	fi
	init_colors
	rc_end "${BRACKET}[ ${BAD}!!${BRACKET} ]${NORMAL}"
	LAST_E_CMD=$2
	return $1
}

eend() {
	eend_sub "${1:-0}" eend && return
	eend=$?
	shift
	[ -z "${*:++}" ] || eerror "$*"
	return $eend
}

ewend() {
	eend_sub "${1:-0}" ewend && return
	eend=$?
	shift
	[ -z "${*:++}" ] || ewarn "$*"
	return $eend
}

veinfo_verbose() {
	if yesno "${EINFO_VERBOSE-}"
	then
veinfo_verbose() {
:
}
	else
veinfo_verbose() {
return 1
}
	fi
	veinfo_verbose
}

veinfo() {
	! veinfo_verbose || einfo ${1+"$@"}
}

veinfon() {
	! veinfo_verbose || einfon ${1+"$@"}
}

vewarn() {
	! veinfo_verbose || ewarn ${1+"$@"}
}

veerror() {
	! veinfo_verbose || eerror ${1+"$@"}
}

vebegin(){
	! veinfo_verbose || ebegin ${1+"$@"}
}

veend() {
	! veinfo_verbose || eend ${1+"$@"}
	return ${1:-0}
}

vewend() {
	! veinfo_verbose || ewend ${1+"$@"}
	return ${1:-0}
}

veindent() {
	! veinfo_verbose || eindent
}

veoutdent() {
	! veinfo_verbose || eoutdent
}

die() {
	eerror ${1+"$@"}
	exit 1
}

yesno() {
	case ${1:-n} in
	[nNFf0]*)
		return 1;;
	esac
	:
}

restart_as_default() {
	restart_as "${POSTSYNC_USER:-portage}" "$@"
}

restart_as() {
	[ x"$1" != x'root' ] || return 0
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
	if [ -z "${3:++}" ]
	then	ebegin "Updating $max_days_file"
	elif [ $1 -ne 0 ]
	then	ebegin "Checking $max_days_file"
	fi
	max_days_file_last=0
	if test -r "$max_days_file"
	then	read max_days_file_last max_days_file_ret <"$max_days_file"
	elif [ -z "${3:++}" ] && ! test -d "$max_days_file_dir"
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
	[ $1 -eq 0 ] || eend 0
	return $max_days_file_ret
}

# Usage: git_clone [-g] depth remote local_path [Description]
# depth 0 or non-numerical means that no --depth argument is passed
# With option -g, apply git_gc afterwards.
git_clone() {
	if [ x"$1" = x'-g' ]
	then	shift
		git_clone_gc=git_gc
	else	git_clone_gc=:
	fi
	[ x"$1" != x'--' ] || shift
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
	if test -d "$git_clone_local/.git"
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

postsync_jobs() {
	[ -n "${POSTSYNC_JOBS:-}" ] || POSTSYNC_JOBS=`nproc` || POSTSYNC_JOBS=
	case ${POSTSYNC_JOBS:-x} in
	*[!0-9]*)
		POSTSYNC_JOBS=;;
	esac
postsync_job() {
:
}
}

is_repository() {
	[ x"$1" = x"$repository_name" ] || {
		[ x"$1" = x'*' ] && [ x"$repository_name" != \
			x"$POSTSYNC_MAIN_REPOSITORY" ]
	}
}

is_git() {
	case $sync_uri in
	*.git)
		return 0;;
	esac
	return 1
}

check_writable() {
	! test -w "$repository_path" || return 0
	eerror "Directory of $repository_name repository non-writable. Try:"
	die "	chown -R $1: $repository_path"
}

postsync_skip() {
	for postsync_skip in ${POSTSYNC_SKIP-}
	do	! is_repository "$postsync_skip" || return 0
	done
	return 1
}

call_egencache() {
	ebegin "Updating metadata cache for the $repository_name repository"
	postsync_jobs
	egencache ${POSTSYNC_JOBS:+"--jobs=$POSTSYNC_JOBS"} \
		"--repo=$repository_name" "$@"
	eend $?
}

egencache_options() {
	[ -n "${POSTSYNC_EGENCACHE_DEFAULT++}" ] || POSTSYNC_EGENCACHE_DEFAULT="
	$POSTSYNC_MAIN_REPOSITORY --update-use-local-desc
	mv --update-use-local-desc mv --changelog-reversed mv --update-changelog"
	egencache_options='--update'
	egencache_options_repo=:
	for egencache_options_i in $POSTSYNC_EGENCACHE_DEFAULT ${POSTSYNC_EGENCACHE-}
	do	if $egencache_options_repo
		then	egencache_options_repo=false
			is_repository "$egencache_options_i"
			egencache_options_pick=$?
		else	egencache_options_repo=:
			[ $egencache_options_pick -ne 0 ] || \
				egencache_options=$egencache_options${egencache_options:+\ }$egencache_options_i
		fi
	done
}

rsync_a() {
	rsync -ltDHS -Pi --modify-window=1 -r --delete --whole-file \
		${PORTAGE_QUIET:+-q} -- "$@"
}

postsync_sync() {
	[ -n "${POSTSYNC_SYNC:+}" ] || \
		POSTSYNC_SYNC:=${SYNC:-rsync://rsync.gentoo.org/gentoo-portage}
postsync_sync() {
:
}
}
