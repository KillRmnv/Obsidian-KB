*Часть конфига посвященная jldts требует настройки под пользователя ОС и саму ОС*

``` json
// Zed settings
//
// For information on how to configure Zed, see the Zed
// documentation: https://zed.dev/docs/configuring-zed
//
// To see all of Zed's default settings without changing your
// custom settings, run `zed: open default settings` from the
// command palette (cmd-shift-p / ctrl-shift-p)
{
  "context_servers": {
    "browser-tools-context-server": {
      "enabled": true,
      "remote": false,
      "settings": {
        "server_args": [
          "@agentdeskai/browser-tools-server@1.2.0"
        ],
        "server_command": "npx",
        "host": "127.0.0.1",
        "port": 3025
      }
    },
    "mcp-server-context7": {
      "enabled": true,
      "remote": false,
      "settings": {
        "context7_api_key": "ctx7sk-f8dd1557-57ca-47fc-b5bd-6d6c07918aea"
      }
    },
    "mcp-server-github": {
      "enabled": true,
      "remote": false,
      "settings": {
        "github_personal_access_token": "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"
      }
    },
  },
  "autosave": {
    "after_delay": {
      "milliseconds": 2000,
    },
  },
  "edit_predictions": {
    "provider": "zed",
  },
  "agent_servers": {
    "pi-acp": {
      "type": "registry"
    },
    "goose": {
    "type": "custom",  
    "command": "goose",  
    "args": ["acp"],  
    "env": {}  
    },
    "kilo": {
      "type": "registry"
    },
    "cline": {
      "type": "registry"
    },
    "opencode": {
      "type": "registry",
    },
    "qwen-code": {
      "type": "registry",
    },
    "mistral-vibe": {
      "type": "registry",
    },
    "Qwen Code": {
      "type": "custom",
      "command": "qwen",
      "args": ["--acp"],
      "env": {},
    },
  },
  "agent": {
    "profiles": {},
    "default_profile": "write",
    "default_model": {
      "provider": "ollama",
      "model": "qwen2.5-coder:3b",
    },
    "favorite_models": [],
    "model_parameters": [],
  },
  "icon_theme": "Zed (Default)",
  "base_keymap": "JetBrains",
  "ui_font_size": 16,
  "buffer_font_size": 15,
  "theme": {
    "mode": "dark",
    "light": "One Light",
    "dark": "Kanagawa Dragon",
  },
  "lsp": {
    "jdtls": {
      "binary": {
        "path": "/home/kirillromanoff/.local/share/nvim/mason/packages/jdtls/bin/jdtls",
      },
      "initialization_options": {
        "bundles": [
          "/home/kirillromanoff/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.53.2.jar",
        ],
        "workspaceFolders": [
          "file:///home/kirillromanoff/University/Editor/GIIS-editor",
        ],
        "settings": {
          "java": {
            "home": "/usr/lib/jvm/java-21-openjdk-amd64",
            "errors": {
              "incompleteClasspath": {
                "severity": "warning",
              },
            },
            "configuration": {
              "updateBuildConfiguration": "interactive",
              "maven": {
                "userSettings": null,
              },
            },
            "import": {
              "gradle": {
                "enabled": true,
              },
              "maven": {
                "enabled": true,
              },
              "exclusions": [
                "**/node_modules/**",
                "**/.metadata/**",
                "**/archetype-resources/**",
                "**/META-INF/maven/**",
                "**/test/**",
              ],
            },
            "referencesCodeLens": {
              "enabled": true,
            },
            "signatureHelp": {
              "enabled": true,
            },
            "implementationCodeLens": {
              "enabled": true,
            },
            "format": {
              "enabled": true,
            },
            "saveActions": {
              "organizeImports": true,
            },
            "contentProvider": {
              "preferred": "fernflower",
            },
            "autobuild": {
              "enabled": true,
            },
            "completion": {
              "favoriteStaticMembers": [
                "org.junit.Assert.*",
                "org.junit.Assume.*",
                "org.junit.jupiter.api.Assertions.*",
                "org.junit.jupiter.api.Assumptions.*",
                "org.junit.jupiter.api.DynamicContainer.*",
                "org.junit.jupiter.api.DynamicTest.*",
              ],
              "importOrder": ["java", "javax", "com", "org"],
            },
          },
        },
      },
    },

    "basedpyright": {
      "settings": {
        "basedpyright.analysis": {
          "typeCheckingMode": "basic",
          "diagnosticMode": "workspace",
        },
      },
    },
  },
  "languages": {
    "Python": {
      "language_servers": ["basedpyright", "ruff", "..."],
    },
  },
  "debugger": {
    "java": {
      "enabled": true,
    },
  },
}
```