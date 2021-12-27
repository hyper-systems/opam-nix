pkgs: compiler:
let
  varsFor = pkg: {
    version = pkg.version;
    name = pkg.pname or pkg.name;
    installed = true;
    preinstalled = true;
    enable = "enable";
    pinned = false;
    build = null;
    hash = null;
    dev = false;
    build-id = null;
    opamfile = null;
    depends = { };

    bin = "${pkg}/bin";
    sbin = "${pkg}/bin";
    lib = "${pkg}/lib";
    man = "${pkg}/share/man";
    doc = "${pkg}/share/doc";
    share = "${pkg}/share";
    etc = "${pkg}/etc";

    __toString = self: self.version;
  };

  otherFor = pkg: { passthru.vars = varsFor pkg; };

  s = builtins.splitVersion compiler;

  compilerVersion = "${builtins.elemAt s 0}_${builtins.elemAt s 1}";

  ocamlPackages =
    pkgs.pkgsBuildHost.ocaml-ng."ocamlPackages_${compilerVersion}";
  ocamlPackages' = pkgs.ocaml-ng."ocamlPackages_${compilerVersion}";

  self = assert pkgs.lib.assertMsg
    (pkgs.stdenv.hostPlatform.system == pkgs.stdenv.buildPlatform.system)
    "Cross-compilation is not supported. See https://github.com/NixOS/nixpkgs/issues/14388"; {
      # Passthru the "build" nixpkgs
      nixpkgs = pkgs;

      # These can come from the bootstrap ocamlPackages
      opam-installer = pkgs.pkgsBuildBuild.opam-installer
        // otherFor pkgs.pkgsBuildBuild.opam-installer;

      # FIXME this should use ocamlPackages (https://github.com/NixOS/nixpkgs/issues/143883)
      # But cross-compilation isn't really a thing for now.
      # Remove assert above when this is resolved.
      ocaml = ocamlPackages'.ocaml // {
        passthru.vars = {
          native = true;
          preinstalled = false;
          native-dynlink = !pkgs.stdenv.hostPlatform.isStatic;
        } // varsFor ocamlPackages'.ocaml;
      };
      num = ocamlPackages'.num // otherFor ocamlPackages'.num;
      ocaml-base-compiler = self.ocaml;
      # FIXME we use ocamlfind from nixpkgs as a convenient way to set OCAMLPATH and things.
      # We should probably reimplement/reuse that part and take actual ocamlfind from the packageset.
      ocamlfind = ocamlPackages'.findlib // otherFor ocamlPackages'.findlib;
    };
in self
