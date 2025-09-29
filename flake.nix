{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { ... }@inputs:
    let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [ raylib ];
        nativeBuildInputs = with pkgs; [ zig ];
      };
    };
}
