module ApplicationHelper
  ENUM_LABELS = {
    "active" => "Ativo",
    "absent" => "Ausente",
    "approved" => "Aprovado",
    "archived" => "Arquivado",
    "asc" => "Crescente",
    "automatic" => "Automática",
    "canceled" => "Cancelado",
    "catalog" => "Catálogo",
    "completed" => "Finalizado",
    "confirmed" => "Confirmado",
    "daily" => "Diária",
    "declined" => "Ausência avisada",
    "desc" => "Decrescente",
    "fixed" => "Fixa",
    "fulfilled" => "Entregue",
    "granted" => "Concedido",
    "inactive" => "Inativo",
    "individual" => "Individual",
    "justified" => "Justificado",
    "manual" => "Manual",
    "monthly" => "Mensal",
    "none" => "Nenhum",
    "participated" => "Participou",
    "pending" => "Pendente",
    "pending_review" => "Aguardando revisão",
    "per_unit" => "Por unidade",
    "predefined" => "Predefinida",
    "profile_only" => "Somente perfil",
    "rejected" => "Rejeitado",
    "rewarded" => "Recompensado",
    "revoked" => "Revogado",
    "scheduled" => "Agendado",
    "squads" => "Squads",
    "unique" => "Única",
    "users" => "Usuários",
    "weekly" => "Semanal"
  }.freeze

  # Retorna o caminho para login com Discord via OmniAuth
  def discord_login_path
    "/auth/discord"
  end

  def enum_label(value)
    ENUM_LABELS.fetch(value.to_s, value.to_s.humanize)
  end

  def event_status_label(event)
    return enum_label(:pending_review) if event.review_available?

    enum_label(event.status)
  end
end
