## 2026-05-30

### Documentacao

- Consolida a documentacao versionada em documentos vivos: `README.md`, `docs/DEVELOPMENT.md`, `docs/ARCHITECTURE.md`, `docs/OPERATIONS.md` e `docs/TESTING.md`.
- Remove guias historicos ou duplicados de setup, ActiveAdmin, controle de acesso, quick start, status de desenvolvimento e cobertura antiga.
- Reconstroi este changelog a partir do historico de commits para evitar entradas antigas ou especulativas.


### Manutencao

- Atualiza `mocha` para 3.1.0 via PR #26 (`0b69087`).
- Atualiza Rails para 8.1.3 via PR #32 (`8faba37`).

## 2026-05-09

### Adicionado

- Implementa a area de gestao in-app em `/manage`, com dashboard, registro de recursos, CRUD generico, formularios e acoes administrativas por permissao (`ac7a58c`).
- Adiciona `PresentationGuildSeeder` e a task `demo:seed_presentation_guild` para gerar dados de apresentacao (`ac7a58c`).
- Adiciona backfill de roles maximas para preservar acesso administrativo legado (`ac7a58c`).

### Alterado

- Ajusta o acesso administrativo para favorecer `/manage` como painel operacional e manter ActiveAdmin como painel tecnico (`ac7a58c`).
- Refina estilos e estados visuais da loja, pedidos e telas de gestao (`87d59e7`).

## 2026-05-03

### Adicionado

- Adiciona health check completo em `/up/full` (`f458d71`).
- Adiciona webhook interno `POST /webhooks/discord/member_update` para sincronizacao de membro Discord (`f458d71`).
- Adiciona rankings publicos por guilda em `/public/guilds/:guild_id/rankings` (`f458d71`).
- Adiciona `AchievementEvaluator` para avaliacao automatica de conquistas (`f458d71`).
- Adiciona configuracao de Active Record Encryption para tokens Discord persistidos em usuarios (`f458d71`).

### Alterado

- Reforca o hardening de login Discord, tokens, certificados, seeds e validacoes multi-guild (`f458d71`).
- Expande missoes automaticas e testes de servicos relacionados (`f458d71`).
- Melhora o cliente Discord com refresh de token e tratamento mais robusto de chamadas externas (`f458d71`).
- Sanitiza metadados sensiveis em auditoria (`f458d71`).

## 2026-05-02

### Adicionado

- Adiciona categorias de roles, incluindo cargo maximo, e flag `managed_by_app` para cargos gerenciados pela aplicacao (`3bcda37`).
- Adiciona adaptador de permissao do ActiveAdmin e expande permissao por `PermissionGroup` (`3bcda37`).
- Adiciona jobs e servicos de sincronizacao Discord: roles da guilda, roles de membros e reconciliacao de cargos gerenciados pelo app (`d604f36`).
- Adiciona auditoria para criacao, resposta e finalizacao de eventos (`a77eecb`).
- Implementa missoes v1 com submissao, revisao, recompensa, pedidos de missao e avaliacao automatica (`0d19823`).
- Implementa telas e administracao de conquistas e certificados (`297c8ce`).
- Implementa rankings configuraveis por guilda, com calculadora de metricas e exibicao autenticada (`ca60845`).
- Implementa loja com itens, pedidos, checkout, estoque, cancelamento/rejeicao com reembolso e auditoria (`7ca91f2`).
- Adiciona navegacao compartilhada de membro e smoke tests de navegacao/ActiveAdmin (`7ca91f2`).

### Alterado

- Move logica Discord antes concentrada em `User` para servicos dedicados (`d604f36`).
- Atualiza documentacao operacional e plano de implementacao conforme os modulos entregues (`7ca91f2`).

## 2026-03-24

### Adicionado

- Implementa fluxo de eventos com recorrencia, participacao, RSVP, revisao e telas de membro/admin (`901572f`).

### Alterado

- Refatora telas de squads com melhorias de interface, revisao e suporte a emblema (`6699bfd`).
- Atualiza `devise` para 5.0.3 via PR #27 (`7c35c85`).

## 2026-03-12

### Adicionado

- Adiciona multiplos personagens por usuario, personagem principal e templates de personagem por guilda (`f13ed40`).
- Implementa `PermissionGroup`, vinculo com roles, controle de acesso por permissao e timestamp de sincronizacao de roles Discord (`9c3942d`).
- Implementa gestao de squads com criacao, convites, lideranca, solicitacao de alteracao de perfil e revisao administrativa (`6cb2d1a`).

### Alterado

- Ajusta a logica de verificacao de permissoes de usuario (`67f133e`).

## 2026-03-09

### Manutencao

- Atualiza dependencias via Dependabot: `brakeman` 8.0.4, `actions/upload-artifact` 7, `selenium-webdriver` 4.41.0, `devise` 5.0.2, `solid_queue` 1.3.2, `web-console` 4.3.0, `bootsnap` 1.23.0, `mocha` 3.0.2 e `faraday` 2.14.1.

## 2026-02-15

### Adicionado

- Implementa gerenciamento de personagens de jogo com controllers, views, modelo, fixtures e testes (`5307afe`).
- Adiciona telas de dashboard, perfil e fluxo restrito da area autenticada (`5307afe`).

### Alterado

- Atualiza estilos da aplicacao e suporte visual das telas de acesso/perfil (`5307afe`).

## 2026-02-09

### Testes

- Adiciona stubs para API do Discord e melhora testes de integracao de autenticacao/acesso (`45827f8`).

### Manutencao

- Atualiza `bootsnap` no lockfile (`1974bd9`).

## 2026-02-08

### Adicionado

- Implementa ActiveAdmin com recursos para guilds, users, roles, squads e dashboard (`458dacd`).
- Configura Devise, OmniAuth Discord, login OAuth, tela de acesso restrito e servico inicial de guild Discord (`458dacd`, `50245b7`).
- Adiciona tasks `discord:*` para criar/listar/sincronizar guilds e configurar cargo requerido (`458dacd`).
- Implementa controle de acesso por servidor/cargo Discord e helpers de sessao/autorizacao (`50245b7`, `b464819`).
- Adiciona `DevSessionsController`, login de desenvolvimento, `script/create_first_admin.rb`, `Procfile.dev` e setup de Solid Queue/Cache/Cable (`c73d8ee`).
- Adiciona documentacao inicial de setup e ambiente (`d38087a`, `c73d8ee`).

### Corrigido

- Passa a versionar `config/credentials.yml.enc` removendo-o do `.gitignore` (`f61a122`).
- Corrige comando do Brakeman removendo `--ensure-latest` (`8c86560`).
- Aplica ajustes de RuboCop em admin, rotas, tasks e testes (`e67c416`).

### Manutencao

- Atualiza dependencias via Dependabot: `bootsnap` 1.22.0, `solid_queue` 1.3.1, `selenium-webdriver` 4.40.0, `puma` 7.2.0, `thruster` 0.1.18, `turbo-rails` 2.0.23 e `brakeman` 8.0.1.

## 2026-01-14

### Adicionado

- Implementa certificados, certificados de usuario, requisitos de certificados por role e transacoes de moeda (`b9d2d95`).
- Adiciona fixtures e testes de modelo para certificados e economia interna (`b9d2d95`).

## 2026-01-13

### Adicionado

- Cria a aplicacao Rails com DevContainer, PostgreSQL, CI, RuboCop, Brakeman, bundler-audit, Puma, Propshaft, Importmap, Hotwire e Tailwind (`c79b456`, `ccb5137`).
- Adiciona schema inicial, `LICENSE`, configuracao de testes e base para system tests (`175ff8f`, `05d3249`, `65088df`, `b4aff3b`).
- Implementa os modelos iniciais de guilda, usuario, cargo, squad, vinculo usuario/cargo e auditoria, com migrations, fixtures e testes (`3ceb2ea`).
- Implementa modelos iniciais de eventos, participacoes, missoes, submissoes e Active Storage, com fixtures e testes (`d0e0916`).
- Implementa conquistas e vinculo de conquistas por usuario, com fixtures e testes (`59085cb`).

### Manutencao

- Atualiza GitHub Actions `actions/cache`, `actions/checkout` e `actions/upload-artifact` via Dependabot (`cebdfca`, `0d5c416`, `fadbb3a`).
- Atualiza `bootsnap` para 1.21.0 via PR #4 (`b460aa4`).
