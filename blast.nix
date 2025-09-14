{
  mixRelease,
  fetchMixDeps,
  erlang,
  elixir,
}:
mixRelease rec {
  pname = "blast";
  version = "0.10.0";
  src = ./.;

  buildInputs = [
    elixir
    erlang
  ];
  packages = [ erlang ];

  mixFodDeps = fetchMixDeps {
    inherit pname version;

    src = ./.;
    sha256 = "sha256-XD5Ey7Nw2CtDzev/mNK8KkQz4pfuC1ayhShKXeOSIAU=";
  };

  installPhase = ''
    runHook preInstall

    mix escript.build
    mkdir -p "$out/bin"
    mv ./blast "$out/bin"

    runHook postInstall
  '';
}
