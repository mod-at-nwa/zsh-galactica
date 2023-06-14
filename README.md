# ZSH-GALACTICA

## Description
An oh-my-zshell plugin to use OpenAI's GPT to complete commands
and edit files. Inspired by Battlestar Galactica's Captain Adama.

zsh-galactica uses roles to enable different functions of the plugin.
Currently there are two roles: `quick-cli` and `script-maker`.

Quick-cli is used to complete commands. Give GPT a clue and it will
do its best to fill in the rest.

Script-maker is used to create and edit scripts. This is an alpha
release level work in progress, but it may be useful.

This plugin is a work in progress. It's not complete but still
quite useful.

```
❯ grole
# select quick-cli
❯ hello world; ^G^G
❯ echo "hello world"
hello world
```

Other completion examples:
```
❯ what's my ip address; ^G^G
❯ cd to default syslog location; ^G^G
```

## Installation
1. Use git to clone this repo into your oh-my-zsh custom plugins directory: `git clone https://github.com/mod-at-arktech/zsh-galactica.git $ZSH_CUSTOM/plugins/zsh-galactica`
2. `cd !$ && source rolesetup.sh`
3. Then add the plugin to your .zshrc file, somewhere after fzf: `plugins=(fzf zsh-galactica)`
4. Set OPENAI_API_KEY in your `.zshrc` or `.zshenv` file. You can get an API key from (OpenAI)[https://beta.openai.com/].

## Powerlevel10k
If you use powerlevel10k, you can add the following to your `.p10k.zsh` file to add a role indicator to your prompt:
```
galactica_role
```
Put this line in the `typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` section of your `.p10k.zsh` file.
Also, for color specification:
```
typeset -g  POWERLEVEL9K_GALACTICA_ROLE_FOREGROUND='black'
typeset -g  POWERLEVEL9K_GALACTICA_ROLE_BACKGROUND='white'
```

## Usage
+ `^G^R` or `grole` to select a role
+ `^G^G` to complete the current command
+ `galactica-help` for more information
# zsh-galactica
