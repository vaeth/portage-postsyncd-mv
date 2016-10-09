#!/bin/sh
# This file must be sourced. The above line is only for editors
[ -n "${1-}" ] || exit 0
: ${POSTSYNC_MAIN_REPOSITORY:=gentoo}
case $only_main in
'+')
	[ x"${1-}" = x"$POSTSYNC_MAIN_REPOSITORY" ] || exit 0;;
'-')
	[ x"${1-}" != x"$POSTSYNC_MAIN_REPOSITORY" ] || exit 0;;
esac

repository_name=$1
sync_uri=$2
repository_path=$3

init_vars() {
	option_quiet=
	option_verbose=
	[ -z "${PORTAGE_QUIET:++}" ] || {
		unset EINFO_QUIET EINFO_VERBOSE
		option_quiet=-q
	}
	! yesno "${EINFO_VERBOSE-}" || option_verbose=-v
init_vars() {
	:
}
}

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
	init_vars
	if yesno "${EINFO_QUIET-}"
	then
einfo_quiet() {
:
}
	else
einfo_quiet() {
	return 1
}
		return 1
	fi
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

ebeginl() {
	! einfo_quiet || return 0
	init_colors
	output_l " ${GOOD}*$NORMAL " "${*-} ..." ebeginl
}

ebeginv() {
	init_vars
	if [ -n "$option_verbose" ]
	then	ebeginl "$@"
	else	ebegin "$@"
	fi
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
	init_vars
	if yesno "${EINFO_VERBOSE-}" && ! yesno "${EINFO_QUIET-}"
	then
veinfo_verbose() {
:
}
	else
veinfo_verbose() {
return 1
}
		return 1
	fi
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

vebeginl(){
	! veinfo_verbose || ebeginl ${1+"$@"}
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
	[nNfF0-]*|[oO][fF]*)
		return 1;;
	esac
	:
}

restart_as_default() {
	[ -n "${POSTSYNC_REPO_USER++}" ] || POSTSYNC_REPO_USER='** portage'
	restart_as_default=
	restart_as_default_repo=:
	case $- in
	*f*)
		restart_as_default_end=:;;
	*)
		set -f
		restart_as_default_end='set +f';;
	esac
	for restart_as_default_i in $POSTSYNC_REPO_USER
	do	if $restart_as_default_repo
		then	restart_as_default_repo=false
			is_repository "$restart_as_default_i"
			restart_as_default_pick=$?
		else	restart_as_default_repo=:
			[ $restart_as_default_pick -ne 0 ] || {
				restart_as_default=$restart_as_default_i
				break
			}
		fi
	done
	$restart_as_default_end
	restart_as "${restart_as_default:-root}" "$@"
}

is_valid_user() {
	case ${1:-/} in
	*[!0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_.,]*)
		return 1;;
	esac
	:
}

restart_as() {
	restart_as=${1:-root}
	shift
	[ x"$restart_as" != x'root' ] || return 0
	is_valid_user "$restart_as" || die "Not a valid user: $restart_as"
	[ "`id -u`" -eq 0 ] || {
		HOME=$restart_as_home
		unset restart_as_home
		check_writable "$restart_as"
		return 0
	}
	case $0 in
	/*)
		restart_as_name=$0;;
	*)
		restart_as_name=/etc/portage/repo.postsync.d/${0##*/};;
	esac
	eval "restart_as_home=~$restart_as"
	export restart_as_home
	if [ -z "${POSTSYNC_SHELL:++}" ]
	then	POSTSYNC_SHELL=`command -v sh 2>/dev/null` && \
			[ -n "${POSTSYNC_SHELL:++}" ] || \
			POSTSYNC_SHELL=${PORTAGE_CONFIGROOT-}/bin/sh
	fi
	exec su -p -s "$POSTSYNC_SHELL" -c 'restart_as_name=$1
shift
. "$restart_as_name" "$@"
' "$restart_as" -- "$POSTSYNC_SHELL" "$restart_as_name" "$@"
	die "Failed to exec $restart_as_name as $restart_as"
}

filestamp_file() {
	case $1 in
	/*)
		filestamp_file=$1;;
	*/*)
		filestamp_file=$repository_path/${1#./};;
	*)
		filestamp_file=$repository_path/local/timestamps/$1;;
	esac
}

check_readable() {
	case $1 in
	/*)
		test -r "$1"
		return;;
	esac
	test -r "$repository_path/$1"
}

is_number() {
	case ${1:-x} in
	*[!0123456789]*)
		return 1;;
	esac
	:
}

current_date() {
	current_date=`date +%s` || current_date=
	is_number "$current_date" || {
		current_date=0
		eerror 'Failed to get current date'
		return 1
	}
}

# Usage: max_days_file $days $file [$not_exist] [$append_to_not_exist]
# returns success if filestamp in $file (in repository_path or local/timestamps
# unless a more complete path is specified) is maximally $days old.
# $days=0 counts as infinity (always success). Non-numerical $days means never.
# If $not_exist (in repository_path unless a complete path is specified)
# is non-empty and non-readable, failure is returned independent of $file.
# If $not_exist has the special value '' and $days is positive do not check
# date.
# After rturn, the variable $max_days_file contains the timestamp or is empty
# in case of early return.
max_days_file() {
	max_days_file=
	is_number "$1" || return 1
	[ "$1" -ne 0 ] || return 0
	max_days_file=0
	[ -z "${3:++}${4:++}" ] || check_readable "$3${4-}" || {
		einfo "Missing $3${4-}"
		return 1
	}
	filestamp_file "$2"
	test -r "$filestamp_file" || {
		einfo "Missing filestamp $filestamp_file"
		return 1
	}
	read max_days_file current_date <"$filestamp_file"
	is_number "$max_days_file" || max_days_file=0
	[ $# -ne 3 ] || [ -n "$3" ] || return 0
	current_date || return 1
	# 24 * 60 * 60 = 86400 seconds in one day
	if [ $(( $1 * 86400 )) -gt "$(( $current_date - $max_days_file ))" ]
	then	einfo "Recent filestamp $filestamp_file"
		return 0
	fi
	einfo "Old filestamp $filestamp_file"
	return 1
}

# Usage: update_days_file $days $file
# Create/update timestamp in $file (in repository_path or local/timestamps
# unless a more complete path is specified) unless $days is non_numeric
# or zero.
update_days_file() {
	is_number "$1" && [ $1 -ne 0 ] || return 0
	filestamp_file "$2"
	update_days_file=${filestamp_file%/*}
	test -d "$update_days_file" || mkdir -p -- "$update_days_file" || {
		eerror "failed to create $update_days_file"
		return 1
	}
	current_date
	update_days_file=`LC_ALL=C LC_TIME=C date -R || :` || \
		update_days_file=
	ebegin "Updating $filestamp_file"
	printf "%s %s\n" "$current_date" \
		"$update_days_file" >|"$filestamp_file"
	eend $? "Failed to create $filestamp_file"
}

local_path() {
	local_path=${1%/}
	case ${local_path:-.} in
	/*)
		:;;
	.)
		local_path=$repository_path;;
	*)
		local_path=$repository_path/${local_path%/.};;
	esac
}

# Usage: git_pull depth local_path [Description]
# eend has to be printed afterwards, possibly using $local_path
git_pull() {
	git_pull_depth=$1
	local_path "$2"
	shift 2
	if [ $# -gt 0 ]
	then	[ -z "${*:++}" ] || ebeginl "$*"
	else	ebeginl "Updating $local_path"
	fi
	init_vars
	if ! is_number "${git_pull_depth:-x}" || [ $git_pull_depth -eq 0 ]
	then	git -C "$local_path" pull $option_quiet
		return
	fi
	# git pull typically fails in shallow repositories.
	# Use the same strategy as portage: git fetch && git reset --merge
	git_pull_remote=`git -C "$local_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'` \
		|| return
	git -C "$local_path" fetch $option_quiet "--depth=$git_pull_depth" "${git_pull_remote%%/*}" \
		|| return
	git -C "$local_path" reset --merge "$git_pull_remote" $option_quiet
}

# Usage: git_new depth remote local_path [Description]
# eend has to be printed afterwards, possibly using $local_path
git_new() {
	git_new_depth=$1
	git_new_remote=$2
	local_path "$3"
	shift 3
	if [ $# -ge 0 ]
	then	[ -z "${*:++}" ] || ebeginl "$*"
	else	ebeginl "Cloning into $local_path"
	fi
	if is_number "$git_new_depth" && [ $git_new_depth -ne 0 ]
	then	set -- --depth="$git_new_depth"
	else	set -- a
		shift
	fi
	init_vars
	git clone $option_quiet ${1+"$@"} -- "$git_new_remote" "$local_path"
}

# Usage: git_clone [-g] [--] depth remote local_path [Description]
# depth 0 or non-numerical means that no --depth argument is passed
# With option -g, apply git_repack afterwards.
git_clone() {
	if [ x"$1" = x'-g' ]
	then	shift
		git_clone_repack=git_repack
	else	git_clone_repack=:
	fi
	[ x"$1" != x'--' ] || shift
	git_clone_depth=$1
	git_clone_remote=$2
	local_path "$3"
	shift 3
	if test -d "$local_path/.git"
	then	git_pull "$git_clone_depth" "$local_path" ${1+"$@"}
	else	git_new "$git_clone_depth" "$git_clone_remote" \
			"$local_path" ${1+"$@"}
	fi || eend $? "Try to remove $local_path" \
		&& $git_clone_repack "$local_path"
}

# Usage: git_repack dir [message]
git_repack() {
	local_path "$1"
	if [ -n "${2:++}" ]
	then	ebeginl "$2"
	else	ebeginl "Calling git-repack for $local_path"
	fi
	init_vars
	eval git -C \"\$local_path\" repack -a -d ${option_quiet:+>/dev/null}
	eend $?
}

git_repack_days() {
	[ -n "${POSTSYNC_DAYS_GIT_REPACK_REPO:++}" ] || \
		POSTSYNC_DAYS_GIT_REPACK_REPO='* 30'
	git_repack_days=
	git_repack_days_repo=:
	case $- in
	*f*)
		git_repack_days_end=:;;
	*)
		set -f
		git_repack_days_end='set +f';;
	esac
	for git_repack_days_i in $POSTSYNC_DAYS_GIT_REPACK_REPO
	do	if $git_repack_days_repo
		then	git_repack_days_repo=false
			is_repository "$git_repack_days_i"
			git_repack_days_pick=$?
		else	git_repack_days_repo=:
			[ $git_repack_days_pick -ne 0 ] || {
				git_repack_days=$git_repack_days_i
				break
			}
		fi
	done
	$git_repack_days_end
}

postsync_jobs() {
	[ -n "${POSTSYNC_JOBS:-}" ] || POSTSYNC_JOBS=`nproc` || POSTSYNC_JOBS=
	is_number "$POSTSYNC_JOBS" || POSTSYNC_JOBS=
postsync_job() {
:
}
}

is_repository() {
	[ x"$1" = x'**' ] || [ x"$1" = x"$repository_name" ] || {
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

git_repository() {
	git_repository=$repository_path/.git
	test -d "$git_repository"
}

check_writable() {
	! test -w "$repository_path" || return 0
	eerror "Directory of $repository_name repository non-writable"
	eerror "Maybe POSTSYNC_CHPERM is not set appropriately"
	exit 1
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
	unset EGENCACHE_DEFAULT_OPTS
	egencache ${POSTSYNC_JOBS:+"--jobs=$POSTSYNC_JOBS"} \
		"--repo=$repository_name" "$@"
	eend $?
}

egencache_options() {
	[ -n "${POSTSYNC_EGENCACHE_DEFAULT++}" ] || \
		POSTSYNC_EGENCACHE_DEFAULT="** --ignore-default-opts ** --update ** --tolerant
$POSTSYNC_MAIN_REPOSITORY --update-use-local-desc"
	[ -n "${POSTSYNC_EGENCACHE++}" ] || \
		POSTSYNC_EGENCACHE='mv --changelog-reversed mv --update-changelogs'
	egencache_options=
	egencache_options_repo=:
	case $- in
	*f*)
		egencache_options_end=:;;
	*)
		set -f
		egencache_options_end='set +f';;
	esac
	for egencache_options_i in $POSTSYNC_EGENCACHE_DEFAULT $POSTSYNC_EGENCACHE
	do	if $egencache_options_repo
		then	egencache_options_repo=false
			is_repository "$egencache_options_i"
			egencache_options_pick=$?
		else	egencache_options_repo=:
			[ $egencache_options_pick -ne 0 ] || \
				egencache_options=$egencache_options${egencache_options:+\ }$egencache_options_i
		fi
	done
	$egencache_options_end
}

rsync_a() {
	init_vars
	rsync -ltDHS --modify-window=1 -r --delete $option_quiet \
		${option_verbose:---progress} ${option_verbose:--vi} -- "$@"
}

postsync_sync() {
	[ -n "${POSTSYNC_SYNC:++}" ] || \
		POSTSYNC_SYNC=${SYNC:-rsync://rsync.gentoo.org/gentoo-portage}
postsync_sync() {
:
}
}
