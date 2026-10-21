{
  description = "DaTab: landing page estática con entorno de desarrollo reproducible";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      sitePackage =
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "datab-site";
          version = "0.1.0";
          src = ./site;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -R . $out/
            runHook postInstall
          '';

          meta = {
            description = "Artefacto estático de la landing de DaTab";
          };
        };

      serveApp =
        system:
        let
          pkgs = pkgsFor system;
          serve = pkgs.writeShellApplication {
            name = "serve";
            runtimeInputs = [ pkgs.live-server ];
            text = ''
              exec live-server --host 127.0.0.1 --port 8080 site
            '';
          };
        in
        {
          type = "app";
          program = "${serve}/bin/serve";
          meta = {
            description = "Sirve site/ con recarga en vivo en http://127.0.0.1:8080";
          };
        };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.git
              pkgs.live-server
              pkgs.nixfmt
            ];
          };
        }
      );

      apps = forAllSystems (system: {
        default = serveApp system;
        serve = serveApp system;
      });

      packages = forAllSystems (system: {
        default = sitePackage system;
        site = sitePackage system;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
