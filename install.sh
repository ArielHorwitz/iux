#! /bin/bash
set -e

INVOKED_COMMAND="$0 $@"
LOGFILE=/tmp/dmd-install.log
USAGE_HELP="\e[3;32mInstall dmd.\e[0m

\e[1;4mUSAGE:\e[0m $(basename $0) [OPTIONS] [COMPONENTS]

\e[1;4mCOMPONENTS\e[0m
  a | all           All components
  p | packages      Sync system packages
  c | crates        Cargo crate installations
  s | scripts       Bin scripts
  g | config        System configurations
  i | icons         Icons
  f | fonts         Fonts
  h | home          Apply home data using homux

\e[1;4mOPTIONS\e[0m
  -f, --force       Do not stop on warnings
  -h, --help        Show this help and exit
"


exec 3>&1 1>/dev/null
printhelp() { printf "$USAGE_HELP" | tee /dev/fd/3 ; }
progress () { printf "\e[32m$1\e[0m\n" | tee /dev/fd/3 ; }
debug () { printf "\e[36m$1\e[0m\n" ; }
notice () { printf "\e[35m$1\e[0m\n" | tee /dev/fd/3 ; }
warn () { printf "\e[1;38;2;255;96;0m$1\e[0m\n" | tee /dev/fd/3 ; }
error () { printf "\e[31m$1\e[0m\n" | tee /dev/fd/3 ; }
exit_error() { error "$1"; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        a | all)             INSTALL_ALL=1; shift ;;
        p | packages)        INSTALL_PACKAGES=1; shift ;;
        c | crates)          INSTALL_CRATES=1; shift ;;
        s | scripts)         INSTALL_SCRIPTS=1; shift ;;
        g | config)          INSTALL_CONFIG=1; shift ;;
        i | icons)           INSTALL_ICONS=1; shift ;;
        f | fonts)           INSTALL_FONTS=1; shift ;;
        h | home)            INSTALL_HOME=1; shift ;;
        -f | --force)        INSTALL_FORCE=1; shift ;;
        -h | --help)         printhelp; exit 0 ;;
        *)                   exit_error "Unknown option: $1" ;;
    esac
done

INSTALLATION_OPERATION=
INSTALLATION_COMPONENTS=(packages crates scripts config icons fonts home)
for component_name in ${INSTALLATION_COMPONENTS[@]}; do
    installation_component_name="INSTALL_${component_name^^}"
    [[ -z $INSTALL_ALL ]] || declare "${installation_component_name}=1"
    [[ -z ${!installation_component_name} ]] || INSTALLATION_OPERATION=1
done
[[ $INSTALLATION_OPERATION ]] || exit_error "Nothing to do (try --help)"


printf '' > $LOGFILE
exec 1>>$LOGFILE 2>&1
notice "Logging to: $LOGFILE"
echo "Invoked command with arguments: $INVOKED_COMMAND"
echo "Current working directory: $(pwd)"
echo "Started at: $(date)"

SOURCE_DIR=$(realpath $(dirname $0))
SETUP_DIR=$SOURCE_DIR/setup
CRATES_TARGET=/bin/dmd_cargo_crates
BIN_TARGET=/bin/dmd
ICONS_TAGRET=/usr/share/icons/dmd
FONTS_TARGET_DIR=/usr/share/fonts


[[ -d $SETUP_DIR ]] || exit_error "Setup directory not found: ${SETUP_DIR}"
[[ $EUID -ne 0 ]] || exit_error "Do not run as root."
sudo -v


install_packages_arch() {
    set -e
    if [[ ! -f /etc/arch-release ]]; then
        if [[ $INSTALL_FORCE ]]; then
            warn "Skipping packages installation (not Arch Linux)"
            return
        fi
        exit_error "Cannot install packages (not Arch Linux)"
    fi
    if [[ ! $(command -v paru) ]]; then
        progress "Installing paru..."
        local paru_build_dir=$(mktemp -d)
        sudo pacman -S --needed --noconfirm base-devel git
        git clone --depth 1 --shallow-submodules https://aur.archlinux.org/paru-bin.git $paru_build_dir
        cd $paru_build_dir
        makepkg -si --needed --noconfirm
    fi
    progress "Installing packages..."
    paru -S --needed --noconfirm $(cat $SETUP_DIR/aur.txt)
}

install_crates() {
    set -e
    progress "Installing crates..."
    sudo mkdir --parents $CRATES_TARGET
    sudo chown --recursive $USER $CRATES_TARGET
    for crate_name in $(cat $SETUP_DIR/crates.txt); do
        debug "> $crate_name"
        cargo install --root $CRATES_TARGET $crate_name
    done
    sudo chown --recursive 0 $CRATES_TARGET
}


install_scripts() {
    set -e
    progress "Installing scripts..."
    local staging=$(mktemp -d)
    # stage and remove suffixes
    cp -rt $staging $SOURCE_DIR/bin/*
    find $staging -type f -name "*.*" -execdir bash -c 'mv "$0" "${0%.*}"' {} \;
    # install from staging
    sudo rm -rf $BIN_TARGET
    sudo install --owner root -Dt $BIN_TARGET $staging/*
    # clean up
    rm -rf $staging
}


install_configs() {
    set -e
    progress "Configuring profile..."
    cat $SETUP_DIR/profile.dropin \
        | sed "s|<BIN_TARGET>|$BIN_TARGET|g" \
        | sed "s|<CRATES_TARGET>|$CRATES_TARGET/bin|g" \
        | sudo tee /etc/profile.d/dmd.sh

    progress "Configuring sudoers..."
    cat $SETUP_DIR/sudoers.dropin \
        | sed "s|<BIN_TARGET>|$BIN_TARGET|g" \
        | sudo tee /etc/sudoers.d/dmd
    sudo groupadd -f hardware
    sudo usermod -aG hardware $USER
}


install_icons() {
    set -e
    progress "Installing icons..."
    sudo rm -rf $ICONS_TAGRET
    sudo mkdir -p $ICONS_TAGRET
    sudo cp -rt $ICONS_TAGRET $SOURCE_DIR/icons/*
}


install_fonts() {
    set -e
    progress "Installing fonts..."
    local font_downloads=(
        FiraCodeNerdFont-"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz"
        MononokiNerdFont-"https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Mononoki.tar.xz"
        Ubuntu-"https://assets.ubuntu.com/v1/0cef8205-ubuntu-font-family-0.83.zip"
        Mononoki-"https://github.com/madmalik/mononoki/releases/download/1.6/mononoki.zip"
        NotoColorEmoji-"https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
    )
    local tmpdir=$(mktemp -d)
    fc-cache
    for name_url in ${font_downloads[@]}; do
        local font_name=${name_url%%-*}
        local font_url=${name_url#*-}
        local target_dir=$FONTS_TARGET_DIR/$font_name
        if [[ $(fc-list | grep -i "$target_dir/") ]]; then
            debug "Font '$font_name' already installed at ${target_dir}"
            continue
        fi
        local archive_name=$(basename $font_url)
        local download_file=$tmpdir/$archive_name
        debug "Installing ${name}: ${archive_name} at ${target_dir}"
        curl -sSL $font_url -o $download_file
        sudo rm -rf $target_dir
        sudo mkdir -p $target_dir
        case $archive_name in
            *.zip       ) sudo unzip -q $download_file -d $target_dir ;;
            *.tar.*     ) sudo tar -xf $download_file -C $target_dir ;;
            *.ttf       ) sudo cp $download_file $target_dir ;;
            *           ) exit_error "Unknown file type for font install: $archive_name" ;;
        esac
        sudo chown -R root:root $target_dir
        sudo chmod -R 755 $target_dir
    done
    rm -r $tmpdir
    fc-cache
}


install_home() {
    set -e
    progress "Applying home directory..."
    homux --config-file "$SOURCE_DIR/home/.config/homux/config.toml" apply --verbose
}


config_lemurs() {
    progress "Configuring lemurs..."
    # Add i3 in selection menu
    printf '#! /bin/sh\nexec i3' | sudo tee /etc/lemurs/wms/i3
    sudo chmod 755 /etc/lemurs/wms/i3
    # Enable the systemd service
    sudo systemctl disable display-manager.service
    sudo systemctl enable lemurs.service
}

[[ -z $INSTALL_PACKAGES ]] || install_packages_arch
[[ -z $INSTALL_CRATES ]] || install_crates
[[ -z $INSTALL_SCRIPTS ]] || install_scripts
[[ -z $INSTALL_CONFIG ]] || install_configs
[[ -z $INSTALL_ICONS ]] || install_icons
[[ -z $INSTALL_FONTS ]] || install_fonts
[[ -z $INSTALL_HOME ]] || install_home

progress "Done."
