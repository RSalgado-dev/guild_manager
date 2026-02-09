# 🚀 Como Rodar o Projeto em Desenvolvimento

## Método 1: Com Auto-reload (Recomendado) ⚡

O comando `bin/dev` inicia automaticamente:
- ✅ **Rails server** na porta 3000
- ✅ **Tailwind CSS watcher** (compila automaticamente ao editar arquivos)

```bash
bin/dev
```

Edite qualquer arquivo `.html.erb` e o Tailwind recompila automaticamente!

---

## Método 2: Manualmente

Se preferir controlar cada processo:

### Terminal 1: Rails Server
```bash
bin/rails server
```

### Terminal 2: Tailwind Watcher
```bash
bin/rails tailwindcss:watch
```

Ou compilar uma vez:
```bash
bin/rails tailwindcss:build
```

---

## 📁 Estrutura de Assets

```
app/assets/
  ├── stylesheets/
  │   ├── application.tailwind.css  # Fonte Tailwind (@tailwind directives)
  │   ├── application.css           # CSS geral da aplicação
  │   └── active_admin.scss         # Estilos do ActiveAdmin
  ├── builds/
  │   └── tailwind.css              # Tailwind COMPILADO (gerado automaticamente)
  └── config/
      └── manifest.js               # Configuração do asset pipeline
```

---

## ✅ Checklist de Desenvolvimento

- [ ] Rodei `bin/dev` para iniciar servidor + Tailwind watcher
- [ ] Acesso http://localhost:3000
- [ ] Edito arquivos `.html.erb`
- [ ] Tailwind recompila automaticamente
- [ ] Dou refresh no navegador (F5)
- [ ] Mudanças aparecem instantaneamente!

---

## 🎨 Usando Tailwind CSS

### Classes estão disponíveis em todas as views:

```erb
<div class="bg-blue-500 text-white p-4 rounded-lg shadow-lg">
  <h1 class="text-2xl font-bold">Hello Tailwind!</h1>
</div>
```

### Configuração:
- **Tailwind Config**: `config/tailwind.config.js`
- **Fonte CSS**: `app/assets/stylesheets/application.tailwind.css`

---

## 🐛 Troubleshooting

**Classes Tailwind não funcionam:**
```bash
# Recompilar Tailwind
bin/rails tailwindcss:build

# Ou iniciar watcher
bin/rails tailwindcss:watch
```

**Servidor não inicia:**
```bash
# Matar processos Rails/Puma
pkill -f puma

# Reiniciar
bin/dev
```

**Foreman não encontrado:**
```bash
gem install foreman
```

---

**Desenvolvido com ❤️ usando Rails 8.1 + Tailwind CSS**
