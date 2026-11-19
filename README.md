# Obra 360 — Gestão de Obras

Sistema web de gestão de obras inspirado nas funcionalidades do Obra Prima.
Arquivo único (`index.html`), sem build. Banco no Supabase.

**Versão:** v1.5.0 · Desenvolvido por **DomDevLabs** · domdevlabs@gmail.com

## Módulos
- **Painel / BI**: indicadores, previsto x realizado por obra, fluxo de caixa, pendências
- **Obras**: cadastro, status, BDI
- **Orçamento**: etapas e itens (material, mão de obra, equipamento, serviço)
- **Curva ABC**: classes A/B/C automáticas a partir do orçamento
- **Cronograma**: Gantt com avanço físico x planejado e alerta de atraso
- **Diário de Obra (RDO)**: clima, equipe, equipamentos, atividades, ocorrências, fotos
- **Medição**: % por etapa, acumulado e conta a receber automática
- **Tarefas**: quadro em 3 colunas
- **Financeiro**: contas a pagar/receber, apropriação por etapa
- **Previsto x Realizado**: desvio por etapa e alerta de gasto maior que o avanço
- **Compras e Cotação**: solicitação → cotação → mapa → pedido → recebimento
- **Estoque**: saldos, mínimo, transferência entre obras
- **Fornecedores** e **Portal do Cliente**
- **Usuários**: liberar e-mails (admin / editor / leitor) e aprovar pedidos de acesso
- **Backup e dados**: backup, restauração e dados de exemplo

## Banco (Supabase)
Projeto **Araleo Fragrances**, mas **independente**: só usa `o360_membros`,
`o360_registros`, a função `o360_papel()` e o bucket privado `obra360-fotos`.
Script de referência em [`supabase/001_obra360.sql`](supabase/001_obra360.sql).

- Login com Google ou por e-mail e senha (Supabase Auth).
- Só os e-mails cadastrados em `o360_membros` enxergam os dados (RLS).
- Alterações sincronizam em tempo real entre os usuários.
- Fotos do RDO ficam no Storage, acessadas por URL assinada.

## Publicação
Vercel (projeto `obra360`) em https://obra360app.vercel.app — deploy automático a cada push na `main`.
Depois, no Supabase: Authentication → URL Configuration → adicionar a URL do site
em **Redirect URLs** (para os links de confirmação e de redefinição de senha).
