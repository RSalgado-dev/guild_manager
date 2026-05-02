# Cobertura de Testes

Última atualização: 2026-05-02

## Resumo

A suíte usa Rails Minitest com fixtures, WebMock para isolar chamadas Discord, Mocha para stubs/mocks, ActiveJob helpers para jobs e Capybara/Selenium para smoke tests de navegador.

Todos os comandos devem rodar dentro do DevContainer `guild_manager_devcontainer-app-1`.

## Comandos

```bash
bin/rails test
bin/rails test:system
bin/rubocop
```

Para validar um arquivo específico:

```bash
bin/rails test test/models/store_order_test.rb
bin/rails test test/jobs/discord_members_sync_job_test.rb
```

## Cobertura Atual

- Models: guildas, usuários, roles, squads, eventos, missões, conquistas, certificados, rankings, loja, moeda e auditoria.
- Controllers: autenticação, acesso restrito, dashboard, perfil, eventos, missões, squads, rankings, loja e pedidos.
- Services: Discord API client, sync de roles, reconciliação de roles gerenciadas, ranking calculator e avaliação automática de missões.
- Jobs: sync de roles da guilda, sync de membros e reconciliação de roles gerenciadas.
- System smoke: navegação membro, compra na loja, rankings e leitura de auditoria no ActiveAdmin.

## Regras de Teste

- Nenhum teste deve depender de rede real; use WebMock para Discord.
- Testes de permissão devem cobrir caminhos permitido e negado.
- Mudanças em saldo, XP, estoque, certificados ou roles precisam validar side effects e auditoria.
- Para UI, rode o teste focado e depois `bin/rails test:system`.

## Última Validação Registrada

- `bin/rails test`: 417 testes, 1122 assertions, 0 falhas.
- `bin/rails test:system`: 2 testes, 14 assertions, 0 falhas.
- `bin/rubocop`: 192 arquivos, 0 offenses.
