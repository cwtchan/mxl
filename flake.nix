{
	description = "MXL flake";

	inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    rust-overlay.url = "github:oxalica/rust-overlay";
	};

	outputs = {
		self,
		nixpkgs,
		rust-overlay
	}: let
		overlays = [
			(import rust-overlay)
			(self: super: {
					rust-stable = super.rust-bin.stable."1.88.0".default;
					rust-nightly = super.rust-bin.nightly."2025-06-25".default;
				})
		];

		    allSystems = [
      "x86_64-linux" # 64-bit Intel/AMD Linux
      "aarch64-linux" # 64-bit ARM Linux
      "x86_64-darwin" # 64-bit Intel macOS
      "aarch64-darwin" # 64-bit ARM macOS
    ];

    forAllSystems = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f rec {
          pkgs = import nixpkgs {
            inherit overlays system;
          };
					picojson = pkgs.stdenv.mkDerivation {
    			  pname = "picojson";
    			  version = "1.3.0"; # adjust if needed
    			  src = pkgs.fetchFromGitHub {
    			    owner = "kazuho";
    			    repo = "picojson";
    			    rev = "v1.3.0"; # or a commit hash
    			    sha256 = "sha256-wMYfVuDEBCrU0cl32suCiM9yaayvy1zRkrqVMMLSntY="; # replace with nix-prefetch
    			  };
    			  installPhase = ''
    			    mkdir -p $out/include/picojson
    			    cp picojson.h $out/include/picojson/
    			  '';
    			};
					# benchmark = {
					# 	pname = "benchmark-google";
					# 	version = "v1.1.0";
					# 	src = pkgs.fetchFromGitHub {
					# 	  owner = "google";
					# 	  repo = "benchmark";
					# 	  rev = "v1.1.0";   # or whatever tag your project expects
					#   	sha256 = "0000000000000000000000000000000000000000000000000000"; # placeholder
					# 	};
					# };
					pcapplusplus = pkgs.stdenv.mkDerivation {
				    pname = "PcapPlusPlus";
				    version = "v25.05";
				    src = pkgs.fetchFromGitHub {
    			    owner = "seladb";
    			    repo = "PcapPlusPlus";
    			    rev = "v25.05"; # or a commit hash
    			    sha256 = "sha256-rxX8VZRLXRtpFzMegDqXqmZ5ZpvjAoRqZ6hyhYTemII="; # replace with nix-prefetch
						};
				    nativeBuildInputs = [ pkgs.cmake pkgs.boost pkgs.gcc pkgs.libpcap ];
						cmakeFlags = [
							"-DPCAPPP_BUILD_EXAMPLES=OFF"
							"-DPCAPPP_BUILD_TUTORIALS=OFF"
						];
				  };
					stduuid = pkgs.stduuid.overrideAttrs (old: {
						nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.cmake pkgs.pkg-config ];
  					buildInputs = (old.buildInputs or []) ++ [
    					pkgs.libuuid   # libuuid from util-linux
    					pkgs.gsl       # since you're using gsl::span
  					];
					  cmakeFlags = (old.cmakeFlags or []) ++ [
					    "-DUUID_SYSTEM_GENERATOR=ON"
					    "-DUUID_USING_CX20_SPAN=OFF"
					  ];
					});
        }
      );
  in {
    devShells = forAllSystems ({pkgs, picojson, pcapplusplus, stduuid}: {
      default = pkgs.mkShell rec {
        LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages_latest.libclang.lib];
				nativeBuildInputs = (with pkgs; [cmake pkg-config]);
				buildInputs = [picojson pkgs.catch2_3 stduuid pkgs.libuuid pkgs.gsl pcapplusplus];
				PICOJSON_INCLUDE_DIR = "${picojson}/include";
				PCAPPLUSPLUS_INCLUDE_DIR = "${pcapplusplus}/include/pcapplusplus";
				shellHook = ''
    			export PKG_CONFIG_PATH=${pkgs.libuuid.dev}/lib/pkgconfig:${pkgs.libuuid}/lib/pkgconfig:${pcapplusplus}/lib/pkg-config:$PKG_CONFIG_PATH
					export CPLUS_INCLUDE_PATH=${pkgs.gsl}/include:$CPLUS_INCLUDE_PATH
  			'';
        packages =
          (with pkgs; [
            rust-analyzer
            rust-stable
            clang
						cli11
            cmake
						gsl.dev
						pcapplusplus
						picojson
            pkg-config
						spdlog
          ]) ++ [stduuid];
        };
    	nightly = pkgs.mkShell {
    	  LIBCLANG_PATH = pkgs.lib.makeLibraryPath [pkgs.llvmPackages_latest.libclang.lib];
    	  packages =
    	    (with pkgs; [
    	      rust-analyzer
    	      rust-nightly
    	      pkg-config
						cmake
						clang
    	    ]);
    	  };
      }
    );
		packages = forAllSystems ({pkgs, picojson, pcapplusplus, stduuid}: {
			default = pkgs.stdenv.mkDerivation {
					pname = "mxl";
					version = "0.6.2";
					src = ./.;

					nativeBuildInputs = (with pkgs; [catch2_3 cmake gsl pkg-config]) ++[picojson];
				};
			});
  };
}
