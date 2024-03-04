{ mixRelease, fetchMixDeps, erlang, elixir, }:
let name = "blast";
in mixRelease rec {
  pname = name;
  version = "0.5.0";
  src = ./.;

  buildInputs = [ elixir erlang ];
  packages = [ erlang ];

  mixFodDeps = fetchMixDeps {
    inherit pname;
    inherit version;

    src = ./.;
    sha256 = "sha256-0hOiBf9wrJ92DmrJJvW3vYRSvRCSI99ykAzOyu7HAp0=";
  };

  installPhase = ''
    runHook preInstall

    mix escript.build

    runHook postInstall
  '';

  preFixup = ''
    mkdir -p "$out/bin"
    mv ./blast "$out/bin"
  '';
}
