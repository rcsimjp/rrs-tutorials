{
  description = "RoboCup Rescue Simulation Japanese tutorial";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nodejs_22
              pkgs.nixpkgs-fmt
            ];
            shellHook = ''
              echo "RCRS tutorial development shell (Node $(node --version))"
            '';
          };

          rcrs = pkgs.mkShell {
            packages = [
              pkgs.git
              pkgs.jdk21
              pkgs.python313
              pkgs.uv
              pkgs.ruff
              pkgs.curl
              pkgs.unzip
              pkgs.pkg-config
              pkgs.libspatialindex
            ];
            shellHook = ''
              echo "RCRS agent development shell"
              echo "Java: $(java -version 2>&1 | head -n 1)"
              echo "Python: $(python --version)"
              echo "uv: $(uv --version)"
            '';
          };
        });
    };
}
