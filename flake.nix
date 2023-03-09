{
  description = "European Commission theme with LaTeX/Pandoc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    theme-ec.url = "git+https://code.europa.eu/pol/european-commission-latex-beamer-theme/";
    ec-fonts.url = "git+https://code.europa.eu/pol/ec-fonts/";
    ci-detector.url = "github:loophp/ci-detector";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          overlays =
            [
              inputs.theme-ec.overlays.default
            ]
            ++ inputs.nixpkgs.lib.optional (inputs.ci-detector.lib.notInCI) inputs.ec-fonts.overlays.default;

          inherit system;
        };

        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-full latex-bin latexmk;

          latex-theme-ec = {
            pkgs = [pkgs.latex-theme-ec] ++ inputs.nixpkgs.lib.optional (inputs.ci-detector.lib.notInCI) pkgs.ec-square-sans-lualatex;
          };
        };

        pandoc = pkgs.writeShellApplication {
          name = "pandoc";
          text = ''
            ${pkgs.pandoc}/bin/pandoc \
              --data-dir ${pkgs.pandoc-template-ec} \
              "$@"
          '';
          runtimeInputs = [tex];
        };

        myaspell = pkgs.aspellWithDicts (d: [d.en d.en-science d.en-computers d.fr d.be]);

        pandoc-presentation-app = pkgs.writeShellApplication {
          name = "pandoc-presentation-app";

          text = ''
            export LC_ALL="C"
            export TEXINPUTS="${./.}//:"

            ${pkgs.pandoc}/bin/pandoc \
              --standalone \
              --pdf-engine=lualatex \
              --to=beamer \
              --template=${pkgs.pandoc-template-ec}/templates/beamer-theme-ec.latex \
              --slide-level=2 \
              --shift-heading-level=0 \
              "$@"
          '';

          runtimeInputs = [tex];
        };

        pandoc-presentation = pkgs.stdenvNoCC.mkDerivation {
          name = "ec-latex-beamer-theme--pandoc-presentation";

          src = pkgs.lib.cleanSource ./.;

          buildInputs = [tex];

          # TMPDIR is provided by latexmk, and lualatex needs HOME to be set
          # for temporary files while building
          HOME = "$TMPDIR";
          TEXINPUTS = "${./.}//:";
          LC_ALL = "C";

          buildPhase = ''
            runHook preBuild

            ${pandoc-presentation-app}/bin/pandoc-presentation-app \
               --from=markdown \
               --output=pandoc-presentation.pdf \
               $src/src/pandoc/presentation/*.md

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            install -m644 -D *.pdf --target $out/

            runHook postInstall
          '';
        };

        watch-pandoc-presentation-app = pkgs.writeShellApplication {
          name = "watch-pandoc-presentation";
          text = ''
            echo "Now watching files for changes..."

            while true; do \
              ${pandoc-presentation-app}/bin/pandoc-presentation-app "$@"
              ${pkgs.inotify-tools}/bin/inotifywait --exclude '\.pdf|\.git' -qre close_write .; \
            done
          '';
          runtimeInputs = [tex];
        };
      in {
        # nix fmt
        formatter = pkgs.alejandra;

        # nix run git+https://code.europa.eu/pol/european-commission-latex-beamer-theme/#pandoc-presentation -- --output=output.pdf --from=markdown /path/to/the/file.md
        apps.pandoc-presentation = {
          type = "app";
          program = pandoc-presentation-app;
        };

        # nix run git+https://code.europa.eu/pol/european-commission-latex-beamer-theme/#watch-pandoc-presentation -- --output=output.pdf --from=markdown /path/to/file.md
        apps.watch-pandoc-presentation = {
          type = "app";
          program = watch-pandoc-presentation-app;
        };

        # nix build .#pandoc-presentation
        packages.default = pandoc-presentation;

        # nix develop
        devShells.default = pkgs.mkShellNoCC {
          name = "ec-latex-beamer-theme--devshell";
          buildInputs = [
            tex
            pandoc
            pkgs.nodePackages.cspell
            pkgs.nodePackages.prettier
            myaspell
          ];
        };

        checks.pandoc-presentation = pandoc-presentation;
      };
    };
}
