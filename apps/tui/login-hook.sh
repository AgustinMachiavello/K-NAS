# shellcheck shell=sh
# Linked to /etc/profile.d/k-nas.sh, so every login shell runs it. Keep it POSIX sh.

# Show the K-NAS welcome screen at login (interactive shells only)
case $- in
    *i*)
        if [ -t 0 ] && [ -x /opt/k-nas/apps/tui/main.sh ]; then
            /opt/k-nas/apps/tui/main.sh || true
        fi
        ;;
esac
