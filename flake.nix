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
      in rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            emacs
            texlive.combined.scheme-full
          ];
        };

        # TODO refactor into something more modular
        packages = {
          pdf = pkgs.stdenvNoCC.mkDerivation rec {
            name = "org latex export";
            src = self;
            buildInputs = [ pkgs.coreutils pkgs.emacs pkgs.texlive.combined.scheme-full ]; # TODO minimize tex dependencies
            phases = ["unpackPhase" "buildPhase" "installPhase"];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              emacs -q index.org --batch -f org-latex-export-to-pdf --kill
            '';
            installPhase = ''
              mkdir -p $out
              cp index.pdf $out
            '';
          };

          html = pkgs.stdenvNoCC.mkDerivation rec {
            name = "org html export";
            src = self;
            buildInputs = [ pkgs.coreutils pkgs.emacs ];
            phases = ["unpackPhase" "buildPhase" "installPhase"];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              emacs -q index.org --batch -f org-html-export-to-html --kill
            '';
            installPhase = ''
              mkdir -p $out
              cp index.html $out
            '';
          };
        };
      });
}
