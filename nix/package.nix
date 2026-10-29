{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kartka";
  version = "0.3.0";

  # The notarized release zip from GitHub. To update, change `version` and `hash`.
  # The release notes list the SHA-256; `nix hash convert --to sri <hex>` turns it into `hash`.
  src = fetchurl {
    url = "https://github.com/IAmRadek/kartka/releases/download/v${finalAttrs.version}/Kartka-${finalAttrs.version}.zip";
    hash = "sha256-iHsOuH/noxA1KRh5L1GXmzcf9dlQCt6oi2hfduIy5Hk=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";

  # Fixup strips and patches files, which breaks the app's code signature.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications $out/bin
    cp -R Kartka.app $out/Applications/
    ln -s $out/Applications/Kartka.app/Contents/Resources/kartka $out/bin/kartka
    runHook postInstall
  '';

  meta = {
    description = "Minimal plain text editor for macOS";
    homepage = "https://github.com/IAmRadek/kartka";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "kartka";
  };
})
