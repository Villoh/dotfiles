{
  lib,
  buildGoModule,
  makeWrapper,
  wrapGAppsHook3,
  # Libraries MyGo loads at run time (it has no cgo, so nothing links them).
  glib,
  gtk3,
  pango,
  cairo,
  harfbuzz,
  fontconfig,
  libepoxy,
  libGL,
  wayland,
  libxkbcommon,
  libX11,
  # Fallbacks when the system has none on PATH; NixOS/Home Manager usually does.
  git,
  gnupg,
  chezmoi,
}:

let
  runtimeLibs = [
    glib
    gtk3
    pango
    cairo
    harfbuzz
    fontconfig
    libepoxy
    libGL
    wayland
    libxkbcommon
    libX11
  ];
in
buildGoModule {
  pname = "dotfiles-installer";
  version = "0-unstable";

  # The tests read the real .chezmoi.toml.tmpl, package lists, mise config and install.sh's
  # pins next to installer/.
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ./.
      ../.chezmoi.toml.tmpl
      ../packages/windows
      ../install.sh
      ../dot_config/mise/config.toml
    ];
  };
  modRoot = "installer";
  # Update when go.sum changes: set lib.fakeHash, build, copy the hash it prints.
  vendorHash = "sha256-UbV1WzWv8yoGLGMT710QPMhHyjAvws0sraF5sHyN5no=";

  env.CGO_ENABLED = "0";
  tags = [
    "mygo_nodownload"
    "mygo_noinspector"
  ];
  ldflags = [
    "-s"
    "-w"
  ];

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
  ];
  # GTK's settings schemas, for the file dialog.
  buildInputs = [ gtk3 ];

  dontWrapGApps = true;
  postInstall = ''
    mv $out/bin/installer $out/bin/dotfiles-installer
    install -Dm644 icons/terminal.svg $out/share/icons/hicolor/scalable/apps/dotfiles-installer.svg
    install -Dm644 packaging/dotfiles-installer.desktop $out/share/applications/dotfiles-installer.desktop
  '';
  postFixup = ''
    wrapProgram $out/bin/dotfiles-installer \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}:/run/opengl-driver/lib \
      --suffix PATH : ${
        lib.makeBinPath [
          git
          gnupg
          chezmoi
        ]
      }
  '';

  meta = {
    description = "Material 3 installer for Villoh/dotfiles";
    homepage = "https://github.com/Villoh/dotfiles";
    license = lib.licenses.mit;
    mainProgram = "dotfiles-installer";
    platforms = lib.platforms.linux;
  };
}
