{
  description = "Bitcoin Cost Function Analaysis";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        customTexlive = pkgs.texlive.combine {
          inherit (pkgs.texlive) scheme-medium latex-bin latexmk wrapfig ulem capt-of trimspaces catchfile transparent svg;
        };
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            git-review
          ] ++ packages.pdf.buildInputs ++ packages.html.buildInputs;
        };

        # TODO refactor into something more modular
        # - emacs batch commands to script?
        # - use org-export with new overlay package?
        packages = {
          pdf = pkgs.stdenvNoCC.mkDerivation rec {
            name = "org latex export";
            src = self;
            buildInputs = with pkgs; [ coreutils emacs customTexlive graphviz inkscape ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";

              mkdir -p diagrams/examples

              emacs -Q --batch \
                --eval "(setq org-confirm-babel-evaluate (lambda (lang body) nil))" \
                --eval "(org-babel-do-load-languages 'org-babel-load-languages '((dot . t)))" \
                index.org \
                -f org-latex-export-to-latex \
                --kill

              # tectonic -Z shell-escape might be preferable
              pdflatex --shell-escape index.tex
            '';
            installPhase = ''
              mkdir -p $out
              cp index.pdf $out
            '';
          };

          html = pkgs.stdenvNoCC.mkDerivation rec {
            name = "org html export";
            src = self;
            buildInputs = with pkgs; [ coreutils emacs graphviz ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";

              mkdir -p diagrams/examples

              emacs -Q --batch \
                --eval "(setq org-confirm-babel-evaluate (lambda (lang body) nil))" \
                --eval "(org-babel-do-load-languages 'org-babel-load-languages '((dot . t)))" \
                index.org \
                -f org-html-export-to-html \
                --kill
            '';
            installPhase = ''
              mkdir -p $out
              cp index.html $out
              cp -R diagrams $out/diagrams
            '';
          };
        };
      });
}
