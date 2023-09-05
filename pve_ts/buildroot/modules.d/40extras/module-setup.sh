#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    return 0
}

# called by dracut
install() {
    inst_binary vi || exit 1
    inst_binary curl || exit 1
    return 0
}