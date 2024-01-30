{ lib
, stdenv
, fetchFromSourcehut
, fetchpatch
, gnugrep
, gojq
, busybox
, util-linux
, lisgd
, pn
, inotify-tools
, libnotify
, light
, superd
, file
, mmsd-tng
, isX ? false
, sway, sway-unwrapped, dwm
, bemenu, dmenu
, foot, st
, wvkbd, svkbd
, proycon-wayout, conky
, wtype, xdotool
, mako, dunst
, wob
, swayidle, xprintidle
}:

let
  sxmo-sway = sway.override {
    withBaseWrapper = true;
    withGtkWrapper = true;
    sway-unwrapped = sway-unwrapped.overrideAttrs (super: {
      # https://github.com/swaywm/sway/pull/6455
      patches = (super.patches or [ ]) ++ lib.singleton (fetchpatch {
        url = "https://github.com/swaywm/sway/commit/4666d1785bfb6635e6e8604de383c91714bceebc.patch";
        hash = "sha256-e2++kHvEksPJLVxnOtgidLTMVXQQw8WFXiKTNkVGVW4=";
      });
    });
  };
in

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "unstable-2024-01-01";

  src = fetchFromSourcehut {
    owner = "~mil";
    repo = pname;
    rev = "9b6aa786a0f9d5a31b10f9faad65c7f3d5a28249";
    hash = "sha256-bQ8hBU2GeMU5PDI5KcMg5NFFG86X15O94CL5Oq55loQ=";
  };

  patches = [ ];

  postPatch = ''
    substituteInPlace Makefile --replace '"$(PREFIX)/bin/{}"' '"$(out)/bin/{}"'
    #substituteInPlace Makefile --replace '$(DESTDIR)/usr' '$(out)'
    substituteInPlace setup_config_version.sh --replace "busybox" ""

    # A better way than wrapping hundreds of shell scripts (some of which are even meant to be sourced)
    sed -i '2i export PATH="'"$out"'/bin:${lib.makeBinPath ([
      gojq
      util-linux # setsid, rfkill
      busybox
      lisgd
      pn
      # mnc
      # bonsai
      inotify-tools
      libnotify
      light
      superd
      file
      mmsd-tng
    ] ++ lib.optionals (!isX) [
      sxmo-sway
      bemenu
      foot
      wvkbd
      proycon-wayout
      wtype
      mako
      wob
      swayidle
    ] ++ lib.optionals isX [
      dwm
      dmenu
      st
      svkbd
      conky
      xdotool
      dunst
      xprintidle
    ])}''${PATH:+:}$PATH"' scripts/core/sxmo_common.sh
    sed -i '3i export XDG_DATA_DIRS="'"$out"'/share''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"' scripts/core/sxmo_common.sh

    substituteInPlace $(${gnugrep}/bin/grep -rl '\. sxmo_common.sh') \
      --replace ". sxmo_common.sh" ". $out/bin/sxmo_common.sh"
    #substituteInPlace \
    #  scripts/core/sxmo_winit.sh \
    #  scripts/core/sxmo_xinit.sh \
    #  scripts/core/sxmo_rtcwake.sh \
    3  scripts/core/sxmo_migrate.sh \
    #  --replace "/etc/profile.d/sxmo_init.sh" "$out/etc/profile.d/sxmo_init.sh"
    #substituteInPlace scripts/core/sxmo_version.sh --replace "/usr/bin/" ""
    #substituteInPlace configs/superd/services/* --replace "/usr/bin/" ""
    #substituteInPlace configs/appcfg/sway_template --replace "/usr" "$out"
    #substituteInPlace configs/udev/90-sxmo.rules --replace "/bin" "${busybox}/bin"
    #substituteInPlace scripts/core/sxmo_uniq_exec.sh --replace '$1' '$(command -v $1)'

    #substituteInPlace scripts/core/sxmo_common.sh --replace 'alias rfkill="busybox rfkill"' '#'
    #substituteInPlace configs/default_hooks/sxmo_hook_desktop_widget.sh --replace "wayout" "proycon-wayout"
  '';

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
    "OPENRC=0"
  ];

  meta = with lib; {
    description = "Scripts and small C programs that make the sxmo environment";
    homepage = "https://sxmo.org";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ chuangzhu ];
  };
}