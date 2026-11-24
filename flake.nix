{
  description = "Vulkan development environment for HowToVulkan";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        # Match the LunarG SDK include layout expected by source/main.cpp.
        vulkanSdk = pkgs.symlinkJoin {
          name = "howtovulkan-sdk";
          paths = with pkgs; [
            vulkan-headers
            vulkan-loader
            (lib.getDev vulkan-loader)
            (lib.getDev shader-slang)
            (lib.getLib shader-slang)
            (lib.getDev sdl3)
            glm
          ];
          postBuild = ''
            mkdir -p "$out/include/volk" "$out/include/vma"
            ln -s ${pkgs.vulkan-volk}/include/volk.h "$out/include/volk/volk.h"
            ln -s ${pkgs.vulkan-volk}/include/volk.c "$out/include/volk/volk.c"
            ln -s ${pkgs.vulkan-memory-allocator}/include/vk_mem_alloc.h "$out/include/vma/vk_mem_alloc.h"
            ln -s ${pkgs.lib.getDev pkgs.shader-slang}/include "$out/include/slang"
          '';
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            ninja
            pkg-config
            git
            vulkanSdk
            vulkan-headers
            vulkan-loader
            vulkan-validation-layers
            vulkan-tools
            glslang
            shaderc
            spirv-tools
            shader-slang
            sdl3
            glm
            renderdoc
          ];

          VULKAN_SDK = "${vulkanSdk}";
          VK_ADD_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";

          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [pkgs.vulkan-loader pkgs.shader-slang]}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            if [[ $- == *i* && -z "''${TMUX:-}" ]]; then
              exec ${pkgs.tmux}/bin/tmux
            fi
          '';
        };
      };
    };
}
