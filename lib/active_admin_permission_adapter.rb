class ActiveAdminPermissionAdapter < ActiveAdmin::AuthorizationAdapter
  RESOURCE_PERMISSIONS = {
    "Guild" => "manage_guild_settings",
    "User" => "manage_members",
    "Role" => "manage_roles",
    "PermissionGroup" => "manage_administrative_roles",
    "Squad" => "manage_members",
    "Event" => "manage_events",
    "EventParticipation" => "manage_events",
    "Mission" => "manage_missions",
    "MissionSubmission" => "review_mission_submissions",
    "MissionRequest" => "manage_missions",
    "Achievement" => "manage_achievements",
    "UserAchievement" => "grant_achievements",
    "Certificate" => "manage_certificates",
    "UserCertificate" => "grant_certificates",
    "RoleCertificateRequirement" => "manage_certificates",
    "Ranking" => "manage_rankings",
    "StoreItem" => "manage_store",
    "StoreOrder" => "fulfill_store_orders",
    "CurrencyTransaction" => "manage_store",
    "AuditLog" => "view_audit_logs"
  }.freeze

  def authorized?(action, subject = nil)
    return false unless user
    return false unless user.admin_panel_access?

    subject ||= default_subject
    return true if dashboard_page?(subject)

    permission_for(subject).present?
  end

  def scope_collection(collection, action = ActiveAdmin::Auth::READ)
    return collection.none unless user&.guild_id

    collection_class = collection.respond_to?(:klass) ? collection.klass : collection
    scoped_collection = collection.respond_to?(:where) ? collection : collection_class.all

    if collection_class == StoreOrder
      scoped_collection.joins(:store_item).where(store_items: { guild_id: user.guild_id })
    elsif collection_class == CurrencyTransaction
      scoped_collection.joins(:user).where(users: { guild_id: user.guild_id })
    elsif collection_class == Guild
      scoped_collection.where(id: user.guild_id)
    elsif collection_class == User || collection_class.column_names.include?("guild_id")
      scoped_collection.where(guild_id: user.guild_id)
    else
      scoped_collection
    end
  end

  private

  def default_subject
    resource.respond_to?(:resource_class) ? resource.resource_class : resource
  rescue NoMethodError
    resource
  end

  def dashboard_page?(subject)
    subject.is_a?(ActiveAdmin::Page) && subject.name == "Dashboard"
  end

  def permission_for(subject)
    RESOURCE_PERMISSIONS[subject_class_name(subject)]
  end

  def subject_class_name(subject)
    return subject.name if subject.is_a?(Class)

    subject.class.name
  end
end
