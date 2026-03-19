# Auto-enter arch-dev container if distrobox is available
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERED" ]; then
        if command -v podman > /dev/null 2>&1; then
            podman system renumber > /dev/null 2>&1
        fi
        distrobox enter arch-dev
    fi
fi
