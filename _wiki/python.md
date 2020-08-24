# Python

## Pyenv + Virtualenv

Requirements:

- [pyenv](https://github.com/pyenv/pyenv)
- [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv)
- [virtualenv](https://github.com/pypa/virtualenv)

Installation via Homebrew:

```sh
brew install pyenv pyenv-virtualenv
```

Install a specific Python version:

```sh
pyenv install 2.7.16
```

Create a new virtualenv:

```sh
pyenv virtualenv 2.7.16 my_project_name
```

Uninstall a virtualenv:

```sh
pyenv uninstall my_project_name
```

To automatically switch virtualenv when switching to a project's directory, go to the project's directory and create `.python-version`:

```sh
echo "my_project_name" > .python-version
```
