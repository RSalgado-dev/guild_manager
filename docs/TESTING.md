# Testes

O projeto usa Minitest, fixtures, Capybara/Selenium para system tests, WebMock para bloquear HTTP real e Mocha para mocks/stubs.

## Comandos

Rode dentro do DevContainer.

```bash
bin/rails test
bin/rails test test/models/user_test.rb
bin/rails test:system
bin/rubocop
bin/ci
```

Fluxo recomendado:

1. Rode o teste focado que cobre a mudança.
2. Rode `bin/rails test`.
3. Rode `bin/rubocop`.
4. Use `bin/ci` antes de mudanças maiores.

## Organização

- Model tests: `test/models`.
- Controller tests: `test/controllers`.
- Service tests: `test/services`.
- Job tests: `test/jobs`.
- System smoke tests: `test/system`.
- Fixtures: `test/fixtures`.

## Regras

- Não faça chamadas reais ao Discord em teste; use WebMock, fixtures e stubs.
- Atualize fixtures quando alterar relações, validações ou enums.
- Cubra caminhos permitidos e negados para autenticação, acesso por cargo e permissões.
- Para fluxos financeiros da loja, teste débito, estoque, reembolso e idempotência.
- Para jobs Discord, teste sucesso, erro recuperável e ausência de token quando aplicável.
