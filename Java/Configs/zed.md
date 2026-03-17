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
  "agent": {
    "favorite_models": [],
    "inline_assistant_model": {
      "provider": "lmstudio",
      "model": "nanbeige4.1-3b",
      "enable_thinking": false
    },
    "model_parameters": []
  },
  "autosave": {
    "after_delay": {
      "milliseconds": 2000,
    },
  },
  "agent_servers": {
    "qwen-code": {
      "type": "registry",
    },
    "opencode": {
      "type": "registry",
    },
    "mistral-vibe": {
      "type": "registry",
    },
    "kilo": {
      "type": "registry",
    },
    "cline": {
      "type": "registry",
    },
  },
  "base_keymap": "JetBrains",
  "icon_theme": "Zed (Default)",
  "ui_font_size": 16,
  "buffer_font_size": 15,
  "theme": {
    "mode": "dark",
    "light": "One Light",
    "dark": "JetBrains Dark",
  },

  "lsp": {
    "jdtls": {
      "settings": {
        "java.import.maven.enabled": true,
        "java.import.gradle.enabled": true,
        "java.configuration.updateBuildConfiguration": "automatic",
        "java.configuration.runtimes": [
          {
            "name": "JavaSE-21",
            "path": "/usr/lib/jvm/java-21-openjdk-amd64",
          },
        ],
        "java.project.importOnFirstTimeStartup": "automatic",
        "java.completion.enabled": true,
      },
    },
  },
  "languages": {
    "Java": {
      "language_servers": ["jdtls"],
    },
  },
}

```