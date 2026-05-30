# DevContainer

Esta pasta define o ambiente local do projeto: app Rails e PostgreSQL.

O setup automático fica em `.devcontainer/setup.sh` e roda no `postCreateCommand`. Ele instala gems, prepara o banco e deixa o ambiente pronto para executar comandos Rails dentro do container.

Comando padrão:

```bash
docker exec guild_manager_devcontainer-app-1 bash -lc 'export PATH=/home/vscode/.rbenv/bin:/home/vscode/.rbenv/shims:$PATH; cd /workspace && <command>'
```

Comandos comuns:

```bash
bin/setup --skip-server
bin/dev
bin/rails test
bin/rubocop
```

Documentação principal:

- [README.md](../README.md)
- [docs/DEVELOPMENT.md](../docs/DEVELOPMENT.md)
